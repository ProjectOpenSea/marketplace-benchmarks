const { exec } = require("child_process");
const interpolate = require("color-interpolate");
const parse = require("color-parse");
const colormap = interpolate(["green", "red"]);
const fs = require("fs");
const RPC = process.argv[2];

if (RPC === undefined || RPC == "") throw Error("RPC not set");

// Execute forge tests and capture `stdout`
exec(
    `forge clean && forge test --fork-url ${RPC} -vv`,
    (error, stdout, stderr) => {
        if (error) {
            throw Error("Forge test failed");
        }

        /// {market:{testName:{actionName:{gas,direct}}}}
        let eoaTests = {};
        eoaTests.results = {};
        parseOutput(eoaTests, stdout, false);
        const eoaLatex = generateLatex(
            eoaTests.results,
            "Benchmark Tests (EOA)"
        );

        // Create dir if needed
        if(!fs.existsSync("./results")) {
            fs.mkdirSync("./results");
        }

        fs.writeFileSync("./results/results.tex", eoaLatex);

        /// {market:{testName:{actionName:{gas,direct}}}}
        let directTests = {};
        directTests.results = {};
        parseOutput(directTests, stdout, true);
        const directLatex = generateLatex(
            directTests.results,
            "Benchmark Tests (Direct)"
        );
        fs.writeFileSync("./results/results-direct.tex", directLatex);
    }
);

/**
 * Parses the entire `stdout` from forge. Sets the values in `tests`
 * @param {*} tests The variable which holds test results
 * @param {*} stdout The output from running forge on the market-benchmark tests
 * @param {*} showDirect Show direct contract interactions (as opposed to EOA)
 */
function parseOutput(tests, stdout, showDirect = false) {
    const outputLines = stdout.split("\n");
    let doNextLine = false;
    for (let outputLine of outputLines) {
        outputLine = outputLine.trim();

        if (outputLine == "") {
            doNextLine = false;
        } else if (doNextLine) {
            parseTestLine(tests, outputLine, showDirect);
        } else if (outputLine.includes("Logs:")) {
            doNextLine = true;
        }
    }
}

/**
 * Parses a line of text from the forge output. Sets corresponding keys in `tests`
 */
function parseTestLine(tests, testLine, showDirect) {
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
    if (
        (showDirect && !direct && gasUsage != 0) ||
        (!showDirect && direct && gasUsage != 0)
    )
        return; // Skip unwanted results
    addTestResults(tests, marketName, testName, actionName, gasUsage);
}

function addTestResults(tests, market, testName, actionName, gasUsage) {
    if (!tests.results.hasOwnProperty(market)) {
        tests.results[market] = {};
    }
    if (!tests.results[market].hasOwnProperty(testName)) {
        tests.results[market][testName] = {};
    }
    if (actionName == "") return;
    tests.results[market][testName][actionName] = { gasUsage };
}

/**
 * Generates the latex from the global dictionary `tests`
 * @returns String containing latex
 */
function generateLatex(tests, title) {
    let latex = "";
    const markets = Object.keys(tests);
    const testNames = Object.keys(tests[markets[0]]);

    latex +=
        "\\documentclass[border = 4pt]{standalone}\n\\usepackage{emoji}\n\\usepackage{xcolor}\n\\usepackage{multirow}\n\\begin{document}" +
        `\n\\setemojifont{TwemojiMozilla}\n\\begin{tabular}{ |c|c|${"c|".repeat(
            markets.length
        )} } \n\\hline\n\\multicolumn{${
            2 + markets.length
        }}{|c|}{${title}} \\\\ \n` +
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
        if (actionNames.length == 0) {
            actionNames = [""];
        }

        latex += `\\multirow{${actionNames.length}}{18em}{${testName}}`;
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
                    const percentChange = Math.round(
                        ((gasValue - minGas) * 100.0) / minGas
                    );
                    latex +=
                        `& \\color[RGB]{${color.values[0]},${color.values[1]},${color.values[2]}} ${gasValue}` +
                        (percentChange != 0 ? `(+${percentChange}\\%)` : ``); // Only show percent change if not 0
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
