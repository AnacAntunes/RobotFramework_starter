*** Settings ***
Documentation     Simplified performance tests with K6.
Library           Process
Library           OperatingSystem
Library           DateTime

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
    ${output_file}=    Set Variable    ${REPORT_DIR}/basic_load_test_${timestamp}.log
    Create File    ${output_file}    ${result.stdout}
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
    ${output_file}=    Set Variable    ${REPORT_DIR}/posts_api_test_${timestamp}.log
    Create File    ${output_file}    ${result.stdout}
    Should Be Equal As Integers    ${result.rc}    0
    ...    k6 posts API test failed:\nSTDOUT: ${result.stdout}\nSTDERR: ${result.stderr}
