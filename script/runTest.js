const { exec } = require("child_process");
const interpolate = require("color-interpolate");
const parse = require('color-parse')
const colormap = interpolate(["green", "red"]);
const fs = require("fs");
const RPC = process.argv[2];

if (RPC === undefined || RPC == "") throw Error("RPC not set");
var tests = {};

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

function parseTestLine(testLine) {
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

function generateLatex() {
    let latex = "";
    const markets = Object.keys(tests);
    const testNames = Object.keys(tests[markets[0]]);

    latex += "\\documentclass[12pt]{article}\n\\usepackage{emoji}\n\\usepackage{xcolor}\n\\usepackage{multirow}\n\\begin{document}" +
        `\\setemojifont{TwemojiMozilla}\n\\begin{center}\n\\begin{tabular}{ |c|c|${"c|".repeat(markets.length)} } \n\\hline\n\\multicolumn{${2 + markets.length}}{|c|}{Benchmark Tests} \\\\ \n` +
        "\\hline \n Test Name & Action Name "

    for (const market of markets) {
        latex += `& ${market} `
    }

    latex += "\\\\ \n\\hline\\hline\n";

    for (const testName of testNames) {
        let actionNames = [];
        for (const market of markets) {
            const tempActionNames = Object.keys(tests[market][testName]);
            if (actionNames.length < tempActionNames.length) actionNames = tempActionNames;
        }

        latex += `\\multirow{${actionNames.length}}{16em}{${testName}}`;
        for (const actionName of actionNames) {
            latex += `& ${actionName} `;

            let gasValues = [];
            for (const market of markets) {
                if (tests[market][testName][actionName] === undefined) {
                    gasValues.push(0);
                }
                else {
                    gasValues.push(parseInt(tests[market][testName][actionName].gasUsage));
                }
            }
            const maxGas = Math.max(...gasValues);
            const minGas = Math.min.apply(null, gasValues.filter(Boolean));

            for (const gasValue of gasValues) {
                const color = getColor(minGas, maxGas, gasValue);
                if (gasValue == 0) {
                    latex += `& \\emoji{cross-mark} `
                }
                else {
                    latex += `& \\color[RGB]{${color.values[0]},${color.values[1]},${color.values[2]}} ${gasValue} `
                }
            }

            latex += "\\\\\n";
            latex += `\\cline{2-${2 + markets.length}}`;
        }
        latex += "\\cline{0-1} \n";
    }

    latex += "\\end{tabular}\n\\end{center}\n\\end{document}";

    return latex;
}

function getColor(minGas, maxGas, gas) {
    let color;
    if (minGas == maxGas) {
        color = colormap(0);
    }
    else if (!Number.isFinite(minGas)) {
        color = colormap(0);
    }
    else {
        color = colormap((gas - minGas) * 1.0 / (maxGas - minGas));
    }

    const parsed = parse(color);
    return parsed;
}
