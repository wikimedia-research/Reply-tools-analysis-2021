SELECT
    date_format(dt, 'yyyy-MM-dd') AS attempt_dt,
    wiki AS wiki,
    event.user_id AS user_id,
    event.editing_session_id AS edit_attempt_id,
    event.integration AS editor_type, 
    event.editor_interface AS editor_interface,
    event.bucket AS test_group,
    event.is_oversample AS is_oversample,
    If(event.integration == 'discussiontools', 1, 0) AS reply_tool_used,
-- define edit attempt outcomes as 1 if the edit was published and 0 if it was not 
    If(event.action == 'saveSuccess', 1, 0) AS edit_success,
    CASE
        WHEN min(event.user_editcount) is NULL THEN 'undefined'
        WHEN min(event.user_editcount) < 100 THEN 'under 100'
        WHEN (min(event.user_editcount) >=100 AND min(event.user_editcount < 500)) THEN '100-499'
        ELSE 'over 500'
        END AS edit_count
FROM event.editattemptstep
WHERE
    wiki IN ('frwiki', 'eswiki', 'itwiki', 'jawiki', 'fawiki', 'plwiki', 'hewiki', 'nlwiki',
    'hiwiki', 'kowiki', 'viwiki', 'thwiki', 'ptwiki', 'bnwiki', 'arzwiki', 'swwiki', 'zhwiki',
    'ukwiki', 'idwiki', 'amwiki', 'omwiki', 'afwiki')
-- AB test deployed on Feb 11th and ended on the 10th 
    AND year = 2021 
    AND ((month = 02 AND day >= 12) OR (month >= 03 AND day < 10))
-- look at only desktop events
    AND event.platform = 'desktop'
-- review all talk namespaces
    AND event.page_ns % 2 = 1
-- only users in AB test
    AND event.bucket IN ('test', 'control')
-- discard VE/Wikiditor edits to create new page or section or new discussion tool edits
    AND NOT ((event.action = 'init' AND (event.init_mechanism = 'url-new' OR event.init_mechanism == 'new'))
    OR (event.action = 'init' AND (event.init_type = 'section' AND event.integration ='discussiontools')))
    -- remove bots
    AND useragent.is_bot = false
    AND event.user_id !=0
GROUP BY
    date_format(dt, 'yyyy-MM-dd'),
    wiki,
    event.user_id,
    event.editing_session_id,
    event.integration,
    event.bucket,
    event.editor_interface,
    event.is_oversample,
    If(event.integration == 'discussiontools', 1, 0),
    If(event.action == 'saveSuccess', 1, 0) 