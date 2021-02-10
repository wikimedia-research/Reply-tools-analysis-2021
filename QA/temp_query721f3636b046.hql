SELECT
    date_format(dt, 'yyyy-MM-dd') AS date,
    wiki AS wiki,
    event.editor_interface AS editor_interface,
    event.platform AS platform,
    event.feature As feature,
    event.integration AS integration,
    event.action AS action,
    COUNT(*) AS events
FROM event_sanitized.visualeditorfeatureuse
WHERE 
-- reviewing a few days prior to confirm when events started firing
    year = 2020 
    AND month >= 09
    AND wiki <> 'testwiki'
GROUP BY
    date_format(dt, 'yyyy-MM-dd'),
    wiki,
    event.editor_interface,
    event.feature,
    event.integration,
    event.platform,
    event.action
