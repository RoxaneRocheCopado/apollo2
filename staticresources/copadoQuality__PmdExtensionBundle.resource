{
    "recordTypeMap": {},
    "RecordSetBundles": [
        {
            "Records": [
                {
                    "attributes": {
                        "type": "copado__JobTemplate__c",
                        "url": "/services/data/v57.0/sobjects/copado__JobTemplate__c/a0u7Z00000Bf5fUQAR"
                    },
                    "copado__ApiName__c": "Run PMD_1",
                    "copado__Type__c": "Standard",
                    "copado__Version__c": 1,
                    "Id": "a0u7Z00000Bf5fUQAR",
                    "LastReferencedDate": "2022-05-18T08:54:59.000+0000",
                    "LastViewedDate": "2022-05-18T08:54:59.000+0000",
                    "Name": "Run PMD"
                }
            ],
            "ObjectType": "copado__JobTemplate__c"
        },
        {
            "Records": [
                {
                    "attributes": {
                        "type": "copado__JobStep__c",
                        "url": "/services/data/v57.0/sobjects/copado__JobStep__c/a0t7Z00000JUhtEQAT"
                    },
                    "copado__ApiName__c": "Run PMD_Execute PMD",
                    "copado__ConfigJson__c": "{\"functionName\":\"RunPmd\",\"parameters\":[{\"name\":\"git_json\",\"value\":\"{$Context.Repository.Credential}\",\"required\":false},{\"name\":\"RulesetFileName\",\"value\":\"ruleset\",\"required\":false},{\"name\":\"testResultIds\",\"value\":\"{$Context.JobExecution__r.DataJson.resultIds}\",\"required\":false},{\"name\":\"branchesAndFileIdJson\",\"value\":\"{$Context.Apex.copadoQuality.RetrieveBranchesAndFileIdForPmdScan}\"},{\"name\":\"deltaScan\",\"value\":\"{$Context.Apex.copadoQuality.IsDeltaScan}\"},{\"name\":\"consolidatedResultId\",\"value\":\"{$Context.JobExecution__r.DataJson.resultId}\"}]}",
                    "copado__CustomType__c": "Function",
                    "copado__JobTemplate__c": "a0u7Z00000Bf5fUQAR",
                    "copado__Order__c": 1,
                    "copado__Type__c": "Function",
                    "Id": "a0t7Z00000JUhtEQAT",
                    "Name": "Execute PMD"
                },
                {
                    "attributes": {
                        "type": "copado__JobStep__c",
                        "url": "/services/data/v57.0/sobjects/copado__JobStep__c/a0t7Z00000JUhtHQAT"
                    },
                    "copado__ApiName__c": "Run PMD_Evaluate PMD Acceptance Criteria",
                    "copado__ConfigJson__c": "{\"functionName\":\"Evaluate_PMD_Acceptance_Criteria\",\"parameters\":[{\"name\":\"acceptanceCriteria\",\"value\":\"{$Context.JobExecution__r.DataJson.acceptanceCriteria}\"},{\"name\":\"sarifFileId\",\"value\":\"{$Context.Apex.copadoQuality.GetSarifFileId}\"},{\"name\":\"sarifFileName\",\"value\":\"pmd-output.sarif.json\"}]}",
                    "copado__CustomType__c": "Function",
                    "copado__JobTemplate__c": "a0u7Z00000Bf5fUQAR",
                    "copado__Order__c": 2,
                    "copado__Type__c": "Function",
                    "Id": "a0t7Z00000JUhtHQAT",
                    "Name": "Evaluate PMD Acceptance Criteria"
                }
            ],
            "ObjectType": "copado__JobStep__c"
        },
        {
            "Records": [
                {
                    "attributes": {
                        "type": "copado__Function__c",
                        "url": "/services/data/v57.0/sobjects/copado__Function__c/a0l7Z000004kLusQAE"
                    },
                    "copado__API_Name__c": "RunPmd",
                    "copado__Image_Name__c": "copado-multicloud-pmd:v1",
                    "copado__Options__c": "[ ]",
                    "copado__Parameters__c": "[ {\n  \"required\" : false,\n  \"name\" : \"git_json\",\n  \"defaultValue\" : \"{$Context.Repository.Credential}\"\n}, {\n  \"required\" : false,\n  \"name\" : \"RulesetFileName\",\n  \"defaultValue\" : \"ruleset\"\n}, {\n  \"required\" : false,\n  \"name\" : \"testResultIds\",\n  \"defaultValue\" : \"{$Context.JobExecution__r.DataJson.resultIds}\"\n}, {\n  \"name\" : \"branchesAndFileIdJson\",\n  \"defaultValue\" : \"{$Context.Apex.copadoQuality.RetrieveBranchesAndFileIdForPmdScan}\"\n},{\n  \"name\" : \"deltaScan\",\n  \"defaultValue\" : \"{$Context.Apex.copadoQuality.IsDeltaScan}\"\n},{\n  \"name\" : \"consolidatedResultId\",\n  \"defaultValue\" : \"{$Context.JobExecution__r.DataJson.resultId}\"\n} ]",
                    "copado__Script__c": "export JAVA_TOOL_OPTIONS=\"-XX:CompressedClassSpaceSize=256m -XX:MaxMetaspaceSize=512m -XX:MaxRAMPercentage=50.0\"\n\nparseBranchesAndFileIdJson() {\n\techo $branchesAndFileIdJson\n    originBranch=$(jq -r '.originBranch' <<< $branchesAndFileIdJson)\n    destinationBranch=$(jq -r '.destinationBranch' <<< $branchesAndFileIdJson)\n    rulesetFileId=$(jq -r '.rulesetFileId' <<< $branchesAndFileIdJson)\n    if [[ \"$originBranch\" == *\"null\"* || \"$destinationBranch\" == \"null\" ]]; then\n  \t\tcopado -p \"Error\" -e \"There was some issue executing PMD. Please check logs for more information\" && exit 1\n\tfi\n}\n\ngetCode() {\n \tcopado -p \"Fetching Git branches: $originBranch\"\n\tmkdir code && cd code\n \tgit_depth=${git_depth:-100}\n \tcopado-git-get --depth \"$git_depth\" \"$originBranch\"\n}\n\ngetDiffFiles() {\n\tcopado -p \"Comparing $originBranch with $destinationBranch to obtain diffs\"\n    git fetch\n    git checkout $destinationBranch\n    git checkout $originBranch\n\tdiff=$(git diff --name-only --diff-filter=d origin/$destinationBranch...origin/$originBranch)\n\tfiles=\"\"\n    echo \"Git Difference\" $diff\n    for file in $diff;\n\tdo  \n    \tfile=$(echo $file| sed 's/.*\\///')\n\t\tfiles=\"$files$file,\" \n\tdone\n\n   \tif [ -z \"$files\" ]\n    then       \n        copado -p \"The PMD scan was skipped because destructive changes are being performed.\"  \n        exit 0\n    else\n        files=${files::-1}\n    fi\n}\n\nremoveUnwantedFiles() {\n\tcd ..\n\tbase_command=\"find 'code/' -type f\"\n    for value in `echo $files | sed 's/[)(]//g' | sed 's/,/ /g'`\n    do\n    \tbase_command=\"${base_command} -not -iname '${value}'\"\n    done\n   \n\tbase_command=\"${base_command} -delete\"\n    eval ${base_command}\n}\n\ngetRuleset() {\n\tcopado -p \"Downloading Ruleset file\"\n\tcopado --downloadfiles \"$rulesetFileId\" --downloaddir /tmp/\n\truleset=$(</tmp/\"$RulesetFileName\")\n}\n\nrunOriginBranchScan() {\n\tcopado -p \"Running PMD Scan\"\n    cat /tmp/ruleset\n\trun.sh pmd -d code/ -f sarif -R /tmp/ruleset > pmd-output.sarif.json || true\n}\n\ngetFilesInDestinationBranch() {\n  \tmkdir dest && cd dest\n  \tcopado-git-get \"$destinationBranch\"\n  \tcd ..\n  \n\tbase_command=\"find 'dest/' -type f\"\n    \n    for value in `echo $files | sed 's/[)(]//g' | sed 's/,/ /g'`\n    do\n    \tbase_command=\"${base_command} -not -iname '${value}'\"\n    done\n\n\tbase_command=\"${base_command} -delete\"\n\n\techo ${base_command}\n\teval ${base_command}\n}\n\nrunDestinationBranchScan() {\n\trun.sh pmd -d dest/ -f sarif -R /tmp/ruleset > pmd-dest-output.sarif.json || true\n}\n\ndeltaScanOutput() {\n######################## DELTA SCAN NODE.JS SCRIPT START ########################\ncat << __EOF__ > ./main.js\nconst fs = require('fs');\n\nconst sarifDest = JSON.parse(fs.readFileSync('pmd-dest-output.sarif.json'));\nconst sarifSrc = JSON.parse(fs.readFileSync('pmd-output.sarif.json'));\n\nconst originalViolations = flatten(sarifDest);\nconst latestViolations = flatten(sarifSrc);\n\nconst deltaViolations = latestViolations.filter( (violation) => isNew(violation, originalViolations));\n\nconst deltaSarif = createDeltaSarif(sarifSrc, deltaViolations);\nfs.writeFileSync('delta.sarif.json', JSON.stringify(deltaSarif, null, 2));\n\nfunction createDeltaSarif(completeSarif, deltaViolations) {\n    const result = completeSarif;\n\n    result.runs[0].tool.driver.rules = result.runs[0].tool.driver.rules.filter((rule) => idInViolations(rule.id, deltaViolations));\n\n    result.runs[0].results = result.runs[0].results.filter((result) => idInViolations(result.ruleId, deltaViolations));\n\n    result.runs[0].results = result.runs[0].results.filter((result) => {\n        result.locations = result.locations.filter((location) => {\n            let isNewLocation = false;\n\n            deltaViolations.forEach((newViolation) => {\n                if (result.ruleId == newViolation.ruleId &&\n                    withoutPrefix(location.physicalLocation.artifactLocation.uri) == newViolation.uri &&\n                    JSON.stringify(location.physicalLocation.region) == JSON.stringify(newViolation.region)) {\n                        isNewLocation = true;\n                    }\n            })\n\n            return isNewLocation;\n        });\n\n        return result.locations.length > 0;\n    });\n\n    return result;\n}\n\n\n\nfunction idInViolations(id, violations) {\n    let result = false;\n\n    violations.forEach((violation) => {\n        if (id == violation.ruleId) {\n            result = true;\n        }\n    });\n\n    return result;\n}\n\nfunction flatten(sarif) {\n    return sarif.runs[0].results.reduce( (result, ruleViolations) =>\n            result.concat(ruleViolations.locations.map((location) => {\n                return {\n                    ruleId: ruleViolations.ruleId,\n                    region: location.physicalLocation.region,\n                    uri: withoutPrefix(location.physicalLocation.artifactLocation.uri)\n                }\n            }))\n    , []);\n}\n\nfunction isNew(violation, originalViolations) {\n    let result = true;\n\n    originalViolations.forEach((originalViolation) => {\n        if (JSON.stringify(originalViolation) == JSON.stringify(violation)) {\n            result = false;\n        }\n    });\n\n\treturn result;\n}\n\nfunction withoutPrefix(uri) {\n    return uri.split('code/').pop().split('dest/').pop();\n}\n__EOF__\n######################## DELTA SCAN NODE.JS SCRIPT END ########################\n\n\tviolations=$(node main.js)\n}\n\nattachTestResults() {\n\tcopado -p \"Uploading Analysis Output\"\n\t\n\tif [ -n \"$testResultIds\" ];\n    then\n      testResultsIds=$(echo $testResultIds | sed -e \"s/\\[//g\" | sed -e \"s/\\]//g\" | sed -e \"s/ //g\" | xargs)\n       for testResultId in `echo $testResultsIds | sed 's/[)(]//g' | sed 's/,/ /g'`\n       do\n       \t   if [ \"$deltaScan\" == 'true' ];\n           then\n               copado -u delta.sarif.json --name \"pmd-output.sarif.json\" --parentid $testResultId\n           else\n               copado -u pmd-output.sarif.json --parentid $testResultId\n           fi \n\t   done\n    fi\n}\n\nattachResult(){\n    if [ \"$deltaScan\" == 'true' ];\n    then\n    copado -u delta.sarif.json --name \"pmd-output.sarif.json\"\n    else\n    copado -u pmd-output.sarif.json\n    fi\n}\n\nattachConsolidatedResult(){\n      if [ \"$deltaScan\" == 'true' ];\n      then\n        copado -u delta.sarif.json --name \"pmd-output.sarif.json\" --parentid $consolidatedResultId\nelse\n        copado -u pmd-output.sarif.json --parentid $consolidatedResultId\n      fi \n}\n\nparseBranchesAndFileIdJson\ngetCode\ngetDiffFiles\nremoveUnwantedFiles\ngetRuleset\nrunOriginBranchScan\nif [ \"$deltaScan\" == 'true' ];\nthen\n\tcopado -p \"Executing Delta Scan\"\n\tgetFilesInDestinationBranch\n\trunDestinationBranchScan\n\tdeltaScanOutput\nfi\nattachTestResults\nattachResult\n\nif [ -n \"$consolidatedResultId\" ];\nthen\n\tattachConsolidatedResult\nfi",
                    "copado__Timeout__c": 1440,
                    "copado__Type__c": "Standard",
                    "copado__Version__c": "1",
                    "copado__Worker_Size__c": "S",
                    "Id": "a0l7Z000004kLusQAE",
                    "LastReferencedDate": "2022-05-17T10:35:14.000+0000",
                    "LastViewedDate": "2022-05-17T10:35:14.000+0000",
                    "Name": "Run PMD"
                },
                {
                    "attributes": {
                        "type": "copado__Function__c",
                        "url": "/services/data/v57.0/sobjects/copado__Function__c/a0l3O000002EsYyQAK"
                    },
                    "copado__ApexClass__c": "copadoQuality.EvaluatePmdCriteriaCallback",
                    "copado__API_Name__c": "Evaluate_PMD_Acceptance_Criteria",
                    "copado__Callback_Type__c": "ApexClass",
                    "copado__Image_Name__c": "copado-multicloud-pmd:v1",
                    "copado__Options__c": "[ ]",
                    "copado__Parameters__c": "[ {\n  \"name\" : \"acceptanceCriteria\",\n  \"defaultValue\" : \"{$Context.JobExecution__r.DataJson.acceptanceCriteria}\"\n}, {\n  \"name\" : \"sarifFileId\",\n  \"defaultValue\" : \"{$Context.Apex.copadoQuality.GetSarifFileId}\"\n}, {\n  \"name\" : \"sarifFileName\",\n  \"defaultValue\" : \"pmd-output.sarif.json\"\n} ]",
                    "copado__Script__c": "export JAVA_TOOL_OPTIONS=\"-XX:CompressedClassSpaceSize=256m -XX:MaxMetaspaceSize=512m -XX:MaxRAMPercentage=50.0\"\n\ngetSarif() {\n\tcopado -p \"Downloading PMD Output Sarif file\" \t\n    if [ ! -z \"$sarifFileId\" -a \"$sarifFileId\" != \"\" ]\n    then\n        copado --downloadfiles \"$sarifFileId\" --downloaddir /tmp/\n\t\tsarifFile=$(</tmp/\"$sarifFileName\")\n\t\techo \"$sarifFile\" > pmd-output.sarif.json\n    else \n    \tcopado -p \"The evaluation of PMD acceptance criteria was skipped because destructive changes are being performed.\" \n    \texit 0\n    fi\n}\n\nevaluationOutput() {\ncopado -p \"Evaluating Acceptance Criteria\"\n######################## ACCEPTANCE CRITERIA EVALUATION NODE.JS SCRIPT START ########################\ncat << __EOF__ > ./main.js\nconst fs = require('fs');\n\nconst jsonAcceptanceCrtieria = \"$acceptanceCriteria\";\nconst acceptanceCriteria = JSON.parse(jsonAcceptanceCrtieria);\n\nconst outputSarif = JSON.parse(fs.readFileSync('pmd-output.sarif.json'));\n\nconst violations = flatten(outputSarif);\n\nconst finalResult = evaluate(violations, acceptanceCriteria);\nfs.writeFileSync('pmd-evaluation-result.json', JSON.stringify(finalResult));\n\n\nfunction evaluate(violations, acceptanceCriteria) {\n    let errorMessage = [];\n    const evaluationResult = [];\n\n    const criteria = [];\n    for (const metric in acceptanceCriteria) {\n        criteria.push({ acceptanceCriteria: acceptanceCriteria[metric], metric: metric })\n    }\n\n    criteria.forEach((criteriaRow) => {\n\n        const violationCount = getViolationsCount(violations, getPriority(criteriaRow.acceptanceCriteria.priority), criteriaRow.metric);\n        const passed = checkIfPass(criteriaRow.acceptanceCriteria.violationFrequency, criteriaRow.acceptanceCriteria.warning, violationCount);\n        evaluationResult.push(passed);\n\n        if (!passed && criteriaRow.acceptanceCriteria.errorDescription) {\n            errorMessage = getErrorMessage(criteriaRow.acceptanceCriteria.errorDescription, criteriaRow.metric, errorMessage);\n        }\n\n    });\n\n    errorMessage = getFinalMessage(evaluationResult, errorMessage);\n\n    return errorMessage;\n}\n\nfunction flatten(sarif) {\n    const result = [];\n    const rules = sarif.runs[0].tool.driver.rules;\n\n    if (sarif.runs[0].results.length > 0) {\n        sarif.runs[0].results.forEach((ruleResult) => {\n            const rule = rules.find((item) => item.id === ruleResult.ruleId);\n\n            result.push({\n                ruleset: rule.properties.ruleset,\n                priority: rule.properties.priority\n            });\n        });\n    }\n\n    return result;\n}\n\nfunction getPriority(priority) {\n    let result;\n\n    switch (priority) {\n        case '1 - High':\n            result = 1;\n            break;\n        case '2 - Medium High':\n            result = 2;\n            break;\n        case '3 - Medium':\n            result = 3;\n            break;\n        case '4 - Medium Low':\n            result = 4;\n            break;\n        case '5 - Low':\n            result = 5;\n            break;\n        case 'All':\n            result = 'All';\n            break;\n        default:\n            break;\n    }\n\n    return result;\n}\n\nfunction getViolationsCount(allViolations, criteriaPriority, criteriaMetric) {\n    const violations = [];\n\n    if (criteriaPriority === 'All' && criteriaMetric === 'All') {\n        violations.push(...allViolations);\n    } else {\n        allViolations.forEach((violation) => {\n            if (matches(criteriaPriority, criteriaMetric, violation.ruleset, violation.priority)) {\n                violations.push(violation);\n            }\n        });\n    }\n\n    return violations.length;\n}\n\nfunction matches(criteriaPriority, criteriaMetric, violationRuleset, violationPriority) {\n    return ((criteriaPriority === 'All' && violationRuleset === criteriaMetric) || (criteriaMetric === 'All' && violationPriority === criteriaPriority) || (violationRuleset === criteriaMetric && violationPriority === criteriaPriority));\n}\n\nfunction checkIfPass(criteriaFrequency, criteriaWarning, violationCount) {\n\n    switch (criteriaFrequency.toLowerCase()) {\n        case 'equals':\n            return violationCount == criteriaWarning;\n        case 'equals or greater than':\n            return violationCount >= criteriaWarning;\n        case 'equals or less than':\n            return violationCount <= criteriaWarning;\n        case 'greater than':\n            return violationCount > criteriaWarning;\n        case 'less than':\n            return violationCount < criteriaWarning;\n        default:\n            return false;\n    }\n}\n\nfunction getErrorMessage(errorDescription, metric, consolidatedMessage) {\n    consolidatedMessage.push({\n        category: metric,\n        message: errorDescription\n    });\n\n    return consolidatedMessage;\n}\n\nfunction getFinalMessage(evaluationResult, errorMessage) {\n    if (evaluationResult.includes(false) && errorMessage.length == 0) {\n        errorMessage.push({\n            category: 'General',\n            message: 'The test failed. Please verify its Acceptance Criteria in the Test’s Settings tab.'\n        });\n    }\n\n    return errorMessage;\n}\n__EOF__\n######################## ACCEPTANCE CRITERIA EVALUATION NODE.JS SCRIPT END ########################\n\texecuteScript=$(node main.js)\n}\n\nattachResult(){\n    copado -u pmd-evaluation-result.json\n}\n\ncheckforErrorAndExit(){\n   evaluationResult=\"$(<pmd-evaluation-result.json)\"\n   error_message=$(jq -r '.[] | .message' <<< $evaluationResult)\n   if [[ \"$error_message\" != \"\" ]]; then\n       copado -p \"Error\" -e \"$error_message\" && exit 1\n   fi\n}\ngetSarif\nevaluationOutput\nattachResult\ncheckforErrorAndExit",
                    "copado__Timeout__c": 1440,
                    "copado__Type__c": "Standard",
                    "copado__Version__c": "1",
                    "copado__Worker_Size__c": "S",
                    "Id": "a0l3O000002EsYyQAK",
                    "LastReferencedDate": "2022-08-19T11:45:00.000+0000",
                    "LastViewedDate": "2022-08-19T11:45:00.000+0000",
                    "Name": "Evaluate PMD Acceptance Criteria"
                }
            ],
            "ObjectType": "copado__Function__c"
        }
    ],
    "blobsByUID": {}
}
