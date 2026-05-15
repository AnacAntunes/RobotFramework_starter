*** Settings ***
Documentation     Suite to validate accessibility (WCAG) with axe-core via SeleniumLibrary.
Library           SeleniumLibrary
Library           OperatingSystem
Library           Collections
Suite Setup       Set Up Environment
Suite Teardown    Tear Down Environment
Test Setup        Open Page
Test Teardown     Close Page

*** Variables ***
${URL}                     https://www.w3.org/WAI/ARIA/apg/example-index/
${AXE_SCRIPT}              ${CURDIR}/../../resources/axe.min.js
${AXE_CDN}                 https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.9.1/axe.min.js
${BROWSER}                 headlesschrome
${MAX_VIOLATIONS}          0
${TAGS_JSON}               ["wcag2a", "wcag2aa"]

*** Test Cases ***
Validate Accessibility With Axe-Core
    [Documentation]    Runs axe-core to validate WCAG 2 A/AA criteria on the target page.
    [Tags]             accessibility    wcag    wcag2a    wcag2aa
    Load Axe (Local Or CDN)
    ${results}=        Run Axe And Get Results    ${TAGS_JSON}
    Print Violations Summary    ${results}
    Validate No Violations    ${results}    ${MAX_VIOLATIONS}

*** Keywords ***
Set Up Environment
    Register Keyword To Run On Failure    Capture Page Screenshot

Tear Down Environment
    Close All Browsers

Open Page
    Open Browser    ${URL}    ${BROWSER}
    Set Selenium Implicit Wait    2 s
    Wait Until Page Contains Element    css:body    10 s

Close Page
    Run Keyword And Ignore Error    Capture Page Screenshot
    Close Browser

Load Axe (Local Or CDN)
    ${exists}=    Run Keyword And Return Status    File Should Exist    ${AXE_SCRIPT}
    Run Keyword If    ${exists}    Load Axe From Local
    ...    ELSE    Load Axe Via CDN
    Wait For Axe To Be Available

Load Axe From Local
    ${axe_script}=    Get File    ${AXE_SCRIPT}
    Execute JavaScript    ${axe_script}

Load Axe Via CDN
    Execute Async JavaScript
    ...    var cb = arguments[arguments.length - 1];
    ...    var s = document.createElement('script');
    ...    s.src = '${AXE_CDN}';
    ...    s.onload = function(){ cb(true); };
    ...    s.onerror = function(){ cb(false); };
    ...    document.head.appendChild(s);

Wait For Axe To Be Available
    Wait Until Keyword Succeeds    10x    1s    Verify Axe Is Available

Verify Axe Is Available
    ${ready}=    Execute JavaScript    return !!(window.axe && window.axe.run);
    Should Be True    ${ready}    msg=axe-core is not available in the page context.

Run Axe And Get Results
    [Arguments]    ${tags_json}
    ${result}=    Execute Async JavaScript
    ...    var cb = arguments[arguments.length - 1];
    ...    axe.run(document, {
    ...      runOnly: { type: 'tag', values: ${tags_json} },
    ...      resultTypes: ['violations']
    ...    }).then(function(r){ cb(r); }).catch(function(e){ cb({error: e && e.message || String(e)}); });
    Should Not Be Equal    ${result}    ${None}    msg=axe.run returned an empty result.
    Dictionary Should Not Contain Key    ${result}    error    axe.run error: ${result}
    [Return]    ${result}

Print Violations Summary
    [Arguments]    ${result}
    ${violations}=    Set Variable    ${result['violations']}
    ${count}=         Get Length      ${violations}
    Log To Console    \n===== WCAG Violations Summary (total: ${count}) =====
    FOR    ${v}    IN    @{violations}
        ${id}=        Get From Dictionary    ${v}    id
        ${impact}=    Get From Dictionary    ${v}    impact
        ${nodes}=     Get From Dictionary    ${v}    nodes
        ${ncount}=    Get Length    ${nodes}
        Log To Console    - ${id} | impact: ${impact} | occurrences: ${ncount}
    END
    Log    ${result}

Validate No Violations
    [Arguments]    ${result}    ${max}
    ${violations}=    Set Variable    ${result['violations']}
    ${count}=         Get Length      ${violations}
    Log    WCAG violations found: ${count}
    Should Be True    ${count} <= ${max}    msg=Found ${count} accessibility violations (allowed limit: ${max}).
    Log    No violations above the configured limit.
