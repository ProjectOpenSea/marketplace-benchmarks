const { exec } = require("child_process");
const interpolate = require("color-interpolate");
const parse = require("color-parse");
const colormap = interpolate(["green", "red"]);
const fs = require("fs");
const RPC = process.argv[2];

if (RPC === undefined || RPC == "") throw Error("RPC not set");

/// {market:{testName:{actionName:{gas,direct}}}}
var tests = {};

// Execute forge tests and capture `stdout`
exec(
    `forge clean && forge test --fork-url ${RPC} -vv`,
    (error, stdout, stderr) => {
        if (error) {
            throw Error("Forge test failed");
        }
        parseOutput(stdout);
        const latex = generateLatex();
        fs.writeFileSync("./results/results.tex", latex);
    }
);

/**
 * Parses the entire `stdout` from forge. Sets the values in `tests` global dictionary
 * @param {*} stdout The output from running forge on the market-benchmark tests
 */
function parseOutput(stdout) {
    const outputLines = stdout.split("\n");
    let doNextLine = false;
    for (let outputLine of outputLines) {
        outputLine = outputLine.trim();

        if (outputLine == "") {
            doNextLine = false;
        } else if (doNextLine) {
            parseTestLine(outputLine);
        } else if (outputLine.includes("Logs:")) {
            doNextLine = true;
        }
    }
}

/**
 * Parses a line of text from the forge output. Sets corresponding keys in `tests` global dictionary
 * @param {*} testLine line of output from forge
 */
function parseTestLine(testLine, showDirect = false) {
    const marketName = testLine.split("]")[0].substring(1);
    const testName = testLine.split(")")[0].split("(")[1];
    const actionName = testLine
        .split(")")[1]
        .split("(")[0]
        .split("--")[0]
        .trim();
    const direct = testLine.includes("(direct)");
    const gasUsage =
        testLine.split("gas:").length > 1
            ? testLine.split("gas:")[1].trim()
            : 0;

    if (showDirect && !direct) return; // Skip EOA calls if want to show direct
    addTestResults(marketName, testName, actionName, direct, gasUsage);
}

function addTestResults(market, testName, actionName, direct, gasUsage) {
    if (!tests.hasOwnProperty(market)) {
        tests[market] = {};
    }
    if (!tests[market].hasOwnProperty(testName)) {
        tests[market][testName] = {};
    }
    tests[market][testName][actionName] = { gasUsage, direct };
}

/**
 * Generates the latex from the global dictionary `tests`
 * @returns String containing latex
 */
function generateLatex() {
    let latex = "";
    const markets = Object.keys(tests);
    const testNames = Object.keys(tests[markets[0]]);

    latex +=
        "\\documentclass[border = 4pt]{standalone}\n\\usepackage{emoji}\n\\usepackage{xcolor}\n\\usepackage{multirow}\n\\begin{document}" +
        `\n\\setemojifont{TwemojiMozilla}\n\\begin{tabular}{ |c|c|${"c|".repeat(
            markets.length
        )} } \n\\hline\n\\multicolumn{${
            2 + markets.length
        }}{|c|}{Benchmark Tests} \\\\ \n` +
        "\\hline \n Test Name & Action Name ";

    for (const market of markets) {
        latex += `& ${market} `;
    }

    latex += "\\\\ \n\\hline\\hline\n";

    for (const testName of testNames) {
        let actionNames = [];
        for (const market of markets) {
            const tempActionNames = Object.keys(tests[market][testName]);
            if (actionNames.length < tempActionNames.length)
                actionNames = tempActionNames;
        }

        latex += `\\multirow{${actionNames.length}}{16em}{${testName}}`;
        for (const actionName of actionNames) {
            latex += `& ${actionName} `;

            let gasValues = [];
            for (const market of markets) {
                if (tests[market][testName][actionName] === undefined) {
                    gasValues.push(0);
                } else {
                    gasValues.push(
                        parseInt(tests[market][testName][actionName].gasUsage)
                    );
                }
            }
            const maxGas = Math.max(...gasValues);
            const minGas = Math.min.apply(null, gasValues.filter(Boolean));

            for (const gasValue of gasValues) {
                const color = getColor(minGas, maxGas, gasValue);
                if (gasValue == 0) {
                    latex += `& \\emoji{cross-mark} `;
                } else {
                    const percentageOfMax = Math.round(
                        (gasValue * 100) / maxGas
                    );
                    latex += `& \\color[RGB]{${color.values[0]},${color.values[1]},${color.values[2]}} ${gasValue} (${percentageOfMax}\\%)`;
                }
            }

            latex += "\\\\\n";
            latex += `\\cline{2-${2 + markets.length}}`;
        }
        latex += "\\cline{0-1} \n";
    }

    latex += "\\end{tabular}\n\\end{document}";

    return latex;
}

/**
 * Generate interpolated color between green and red (green lowest gas, and red highest)
 * @param {*} minGas The minimum gas used for the test
 * @param {*} maxGas The maximum gas used for the test
 * @param {*} gas The gas used by a market for this test
 * @returns The color to display market results as for the test
 */
function getColor(minGas, maxGas, gas) {
    let color;
    if (minGas == maxGas) {
        color = colormap(0);
    } else if (!Number.isFinite(minGas)) {
        color = colormap(0);
    } else {
        color = colormap(((gas - minGas) * 1.0) / (maxGas - minGas));
    }

    const parsed = parse(color);
    return parsed;
}
