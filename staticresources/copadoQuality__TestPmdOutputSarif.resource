{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "PMD",
          "version": "6.43.0",
          "informationUri": "https://pmd.github.io/pmd/",
          "rules": [
            {
              "id": "AvoidDebugStatements",
              "shortDescription": {
                "text": "Avoid debug statements since they impact on performance"
              },
              "fullDescription": {
                "text": "\nDebug statements contribute to longer transactions and consume Apex CPU time even when debug logs are not being captured.\n\nWhen possible make use of other debugging techniques such as the Apex Replay Debugger and Checkpoints that could cover *most* use cases.\n\nFor other valid use cases that the statement is in fact valid make use of the `@SuppressWarnings` annotation or the `//NOPMD` comment.\n        "
              },
              "helpUri": "https://pmd.github.io/pmd-6.43.0/pmd_rules_apex_performance.html#avoiddebugstatements",
              "help": {
                "text": "\nDebug statements contribute to longer transactions and consume Apex CPU time even when debug logs are not being captured.\n\nWhen possible make use of other debugging techniques such as the Apex Replay Debugger and Checkpoints that could cover *most* use cases.\n\nFor other valid use cases that the statement is in fact valid make use of the `@SuppressWarnings` annotation or the `//NOPMD` comment.\n        "
              },
              "properties": {
                "ruleset": "Performance",
                "priority": 3,
                "tags": [
                  "Performance"
                ]
              }
            },
            {
              "id": "DebugsShouldUseLoggingLevel",
              "shortDescription": {
                "text": "Calls to System.debug should specify a logging level."
              },
              "fullDescription": {
                "text": "\nThe first parameter of System.debug, when using the signature with two parameters, is a LoggingLevel enum.\n\nHaving the Logging Level specified provides a cleaner log, and improves readability of it.\n       "
              },
              "helpUri": "https://pmd.github.io/pmd-6.43.0/pmd_rules_apex_bestpractices.html#debugsshoulduselogginglevel",
              "help": {
                "text": "\nThe first parameter of System.debug, when using the signature with two parameters, is a LoggingLevel enum.\n\nHaving the Logging Level specified provides a cleaner log, and improves readability of it.\n       "
              },
              "properties": {
                "ruleset": "Best Practices",
                "priority": 3,
                "tags": [
                  "Best Practices"
                ]
              }
            }
          ]
        }
      },
      "results": [
        {
          "ruleId": "AvoidDebugStatements",
          "ruleIndex": 0,
          "message": {
            "text": "Avoid debug statements since they impact on performance"
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/Fibonacci.cls"
                },
                "region": {
                  "startLine": 3,
                  "startColumn": 16,
                  "endLine": 3,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "DebugsShouldUseLoggingLevel",
          "ruleIndex": 1,
          "message": {
            "text": "Calls to System.debug should specify a logging level."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/Fibonacci.cls"
                },
                "region": {
                  "startLine": 3,
                  "startColumn": 16,
                  "endLine": 3,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "AvoidDebugStatements",
          "ruleIndex": 0,
          "message": {
            "text": "Avoid debug statements since they impact on performance"
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/Fibonacci.cls"
                },
                "region": {
                  "startLine": 7,
                  "startColumn": 16,
                  "endLine": 7,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "DebugsShouldUseLoggingLevel",
          "ruleIndex": 1,
          "message": {
            "text": "Calls to System.debug should specify a logging level."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/Fibonacci.cls"
                },
                "region": {
                  "startLine": 7,
                  "startColumn": 16,
                  "endLine": 7,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "AvoidDebugStatements",
          "ruleIndex": 0,
          "message": {
            "text": "Avoid debug statements since they impact on performance"
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/Fibonacci.cls"
                },
                "region": {
                  "startLine": 11,
                  "startColumn": 16,
                  "endLine": 11,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "DebugsShouldUseLoggingLevel",
          "ruleIndex": 1,
          "message": {
            "text": "Calls to System.debug should specify a logging level."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/Fibonacci.cls"
                },
                "region": {
                  "startLine": 11,
                  "startColumn": 16,
                  "endLine": 11,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "AvoidDebugStatements",
          "ruleIndex": 0,
          "message": {
            "text": "Avoid debug statements since they impact on performance"
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/Fibonacci.cls"
                },
                "region": {
                  "startLine": 15,
                  "startColumn": 16,
                  "endLine": 15,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "DebugsShouldUseLoggingLevel",
          "ruleIndex": 1,
          "message": {
            "text": "Calls to System.debug should specify a logging level."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/Fibonacci.cls"
                },
                "region": {
                  "startLine": 15,
                  "startColumn": 16,
                  "endLine": 15,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "AvoidDebugStatements",
          "ruleIndex": 0,
          "message": {
            "text": "Avoid debug statements since they impact on performance"
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/Fibonacci.cls"
                },
                "region": {
                  "startLine": 19,
                  "startColumn": 16,
                  "endLine": 19,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "DebugsShouldUseLoggingLevel",
          "ruleIndex": 1,
          "message": {
            "text": "Calls to System.debug should specify a logging level."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/Fibonacci.cls"
                },
                "region": {
                  "startLine": 19,
                  "startColumn": 16,
                  "endLine": 19,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "AvoidDebugStatements",
          "ruleIndex": 0,
          "message": {
            "text": "Avoid debug statements since they impact on performance"
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/TestClass.cls"
                },
                "region": {
                  "startLine": 3,
                  "startColumn": 16,
                  "endLine": 3,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "DebugsShouldUseLoggingLevel",
          "ruleIndex": 1,
          "message": {
            "text": "Calls to System.debug should specify a logging level."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/TestClass.cls"
                },
                "region": {
                  "startLine": 3,
                  "startColumn": 16,
                  "endLine": 3,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "AvoidDebugStatements",
          "ruleIndex": 0,
          "message": {
            "text": "Avoid debug statements since they impact on performance"
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/TestClass.cls"
                },
                "region": {
                  "startLine": 7,
                  "startColumn": 16,
                  "endLine": 7,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "DebugsShouldUseLoggingLevel",
          "ruleIndex": 1,
          "message": {
            "text": "Calls to System.debug should specify a logging level."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/TestClass.cls"
                },
                "region": {
                  "startLine": 7,
                  "startColumn": 16,
                  "endLine": 7,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "AvoidDebugStatements",
          "ruleIndex": 0,
          "message": {
            "text": "Avoid debug statements since they impact on performance"
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/TestClass.cls"
                },
                "region": {
                  "startLine": 11,
                  "startColumn": 16,
                  "endLine": 11,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "DebugsShouldUseLoggingLevel",
          "ruleIndex": 1,
          "message": {
            "text": "Calls to System.debug should specify a logging level."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/TestClass.cls"
                },
                "region": {
                  "startLine": 11,
                  "startColumn": 16,
                  "endLine": 11,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "AvoidDebugStatements",
          "ruleIndex": 0,
          "message": {
            "text": "Avoid debug statements since they impact on performance"
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/TestClass.cls"
                },
                "region": {
                  "startLine": 15,
                  "startColumn": 16,
                  "endLine": 15,
                  "endColumn": 20
                }
              }
            }
          ]
        },
        {
          "ruleId": "DebugsShouldUseLoggingLevel",
          "ruleIndex": 1,
          "message": {
            "text": "Calls to System.debug should specify a logging level."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "/app/pmd-bin-6.43.0/code/force-app/main/default/classes/TestClass.cls"
                },
                "region": {
                  "startLine": 15,
                  "startColumn": 16,
                  "endLine": 15,
                  "endColumn": 20
                }
              }
            }
          ]
        }
      ],
      "invocations": [
        {
          "executionSuccessful": true,
          "toolConfigurationNotifications": [],
          "toolExecutionNotifications": []
        }
      ]
    }
  ]
}