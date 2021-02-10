
SELECT
  event.bucket AS test_group,
  wiki As wiki,
  IF(event.integration = 'discussiontools', 'discussiontool', 'non_discussion_tool') AS event_type,
  COUNT (DISTINCT event.user_id) AS user,
  COUNT(*) AS init_events
FROM event.editattemptstep
WHERE
  year = 2021 
-- review wikis where AB test deployed
  AND wiki IN = 'idwiki'
-- find all reply tool events
  AND event.integration= 'discussiontools'
  AND event.action = 'init'
  AND NOT event.init_type = 'page'
-- remove logged out users that are not in test
  AND event.user_id != 0
GROUP BY 
  event.bucket,
  wiki
