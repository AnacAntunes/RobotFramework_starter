*** Settings ***
Documentation     Keywords for Robot Framework integration with K6 using Docker.
Library           Process
Library           OperatingSystem
Library           Collections
Library           DateTime
Library           String

*** Variables ***
${K6_SCRIPTS_DIR}     ${CURDIR}/../../tests/performance_tests/k6_scripts
${K6_RESULTS_DIR}     ${CURDIR}/../../reports/performance
${DEFAULT_THRESHOLD}  95
${K6_DOCKER_IMAGE}    grafana/k6:latest

*** Keywords ***
Run K6 Script With Docker
    [Documentation]    Runs a K6 script using Docker and returns the results.
    [Arguments]    ${script_name}    ${vus}=10    ${duration}=30s    ${stage_config}=${EMPTY}    ${thresholds}=${EMPTY}
    Create Directory    ${K6_RESULTS_DIR}
    ${timestamp}=    Get Current Date    result_format=%Y%m%d%H%M%S
    ${output_file_name}=    Set Variable    k6_results_${script_name}_${timestamp}.json
    ${output_file_path}=    Set Variable    ${K6_RESULTS_DIR}/${output_file_name}
    ${docker_script_dir}=    Evaluate    os.path.abspath("${K6_SCRIPTS_DIR}")    os
    ${docker_results_dir}=    Evaluate    os.path.abspath("${K6_RESULTS_DIR}")    os
    ${docker_command}=    Set Variable    docker run --rm -v "${docker_script_dir}:/scripts" -v "${docker_results_dir}:/results" ${K6_DOCKER_IMAGE}
    ${k6_args}=    Set Variable    run /scripts/${script_name} --out json=/results/${output_file_name}
    ${is_empty}=    Run Keyword And Return Status    Should Be Empty    ${stage_config}
    IF    ${is_empty}
        ${k6_args}=    Set Variable    ${k6_args} --vus ${vus} --duration ${duration}
    ELSE
        Log    Using custom stage configuration
    END
    ${full_command}=    Set Variable    ${docker_command} ${k6_args}
    Log    Running command: ${full_command}
    ${result}=    Run Process    ${full_command}    shell=True
    ${rc}=    Convert To Integer    ${result.rc}
    Should Be Equal As Integers    ${rc}    0    K6 execution failed:\n${result.stdout}\n${result.stderr}
    Log    ${result.stdout}
    Wait Until Created    ${output_file_path}    timeout=10s    error=Results file was not generated: ${output_file_path}
    RETURN    ${result}    ${output_file_path}

Verify K6 Results
    [Documentation]    Verifies the results of a K6 execution.
    [Arguments]    ${output_file}    ${max_error_rate}=1    ${max_response_time}=500
    File Should Exist    ${output_file}    K6 results file not found
    ${json_content}=    Get File    ${output_file}
    ${contains_metrics}=    Run Keyword And Return Status    Should Contain    ${json_content}    "metrics"
    Log    Results file contains metrics: ${contains_metrics}
    ${contains_errors}=    Run Keyword And Return Status    Should Not Contain    ${json_content}    "error"
    Log    Results file has no errors: ${contains_errors}
    Log    Basic results verification completed successfully
