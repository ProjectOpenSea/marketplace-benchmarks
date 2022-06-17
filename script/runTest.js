const { exec } = require("child_process");
const fs = require("fs");
const RPC = process.argv[2];

if (RPC === undefined || RPC == "") throw Error("RPC not set");

exec(
    `forge clean && forge test --fork-url ${RPC} -vv`,
    (error, stdout, stderr) => {
        if (error) {
            throw Error("Forge test failed");
        }
        parseOutput(stdout);
    }
);

var tests = {};

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
    console.log(JSON.stringify(tests));
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
        tests[market][testName] = [];
    }
    tests[market][testName].push({ name: actionName, gasUsage, direct });
}
