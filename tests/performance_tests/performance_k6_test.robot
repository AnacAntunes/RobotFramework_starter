*** Settings ***
Documentation     Simplified performance tests with K6.
...               Requires K6 installed: https://k6.io/docs/get-started/installation/
Library           Process
Library           OperatingSystem
Library           DateTime
Suite Setup       Verify K6 Is Installed

*** Variables ***
${K6_SCRIPTS_DIR}     ${CURDIR}/k6_scripts
${REPORT_DIR}         ${CURDIR}/../../reports/performance

*** Test Cases ***
Run Basic K6 Load Test
    [Documentation]    Runs the basic load test using an existing K6 script.
    [Tags]    performance    api    k6
    Create Directory    ${REPORT_DIR}
    File Should Exist    ${K6_SCRIPTS_DIR}/basic_load_test.js
    ${result}=    Run Process
    ...    k6    run    ${K6_SCRIPTS_DIR}/basic_load_test.js    --duration    10s    --vus    5
    ${timestamp}=    Get Current Date    result_format=%Y%m%d%H%M%S
    Create File    ${REPORT_DIR}/basic_load_test_${timestamp}.log    ${result.stdout}
    Should Be Equal As Integers    ${result.rc}    0
    ...    k6 basic load test failed:\nSTDOUT: ${result.stdout}\nSTDERR: ${result.stderr}

Verify Posts API Performance
    [Documentation]    Runs the posts API performance test using an existing K6 script.
    [Tags]    performance    api    k6    posts
    Create Directory    ${REPORT_DIR}
    File Should Exist    ${K6_SCRIPTS_DIR}/posts_api_test.js
    ${result}=    Run Process
    ...    k6    run    ${K6_SCRIPTS_DIR}/posts_api_test.js    --duration    5s    --vus    3
    ${timestamp}=    Get Current Date    result_format=%Y%m%d%H%M%S
    Create File    ${REPORT_DIR}/posts_api_test_${timestamp}.log    ${result.stdout}
    Should Be Equal As Integers    ${result.rc}    0
    ...    k6 posts API test failed:\nSTDOUT: ${result.stdout}\nSTDERR: ${result.stderr}

*** Keywords ***
Verify K6 Is Installed
    ${rc}    ${output}=    Run And Return Rc And Output    k6 version
    Skip If    ${rc} != 0
    ...    K6 is not installed. Install it before running performance tests:\n- Windows: winget install k6\n- Mac: brew install k6\n- Linux: https://k6.io/docs/get-started/installation/
