-- find users that made at least one edit with the reply tool
WITH reply_users AS (
SELECT
    event_user_id as user_id,
    wiki_db as wiki,
    min(event_timestamp) as first_reply_time,
    CASE
        WHEN min(event_user_revision_count) is NULL THEN 'undefined'
        WHEN min(event_user_revision_count) < 100 THEN 'junior'
        ELSE 'non-junior'
        END AS experience_level,
    IF(ARRAY_CONTAINS(revision_tags, 'discussiontools'), 'reply-tool', 'non-reply-tool') AS editing_interface
FROM wmf.mediawiki_history AS mh
WHERE 
    snapshot = '2021-03'
    -- do not include new discussion tool talk page edits
    AND NOT (ARRAY_CONTAINS(revision_tags, 'discussiontools-newtopic'))
    -- include only desktop edits
    AND NOT array_contains(revision_tags, 'iOS')
    AND NOT array_contains(revision_tags, 'Android')
    AND NOT array_contains(revision_tags, 'Mobile Web')
     -- find all edit on talk pages
    AND page_namespace_historical % 2 = 1
    AND event_entity = 'revision'
    AND event_type = 'create'
    -- dates of the AB Test within Feb
    AND event_timestamp >= '2021-02-12' 
    AND event_timestamp <= '2021-03-09'
    -- on all participating wikis
    AND wiki_db IN ('frwiki', 'eswiki', 'itwiki', 'jawiki', 'fawiki', 'plwiki', 'hewiki', 'nlwiki',
    'hiwiki', 'kowiki', 'viwiki', 'thwiki', 'ptwiki', 'bnwiki', 'arzwiki', 'swwiki', 'zhwiki',
    'ukwiki', 'idwiki', 'amwiki', 'omwiki', 'afwiki')
    AND SIZE(event_user_is_bot_by_historical) = 0 
    AND SIZE(event_user_is_bot_by) = 0
    AND event_user_is_anonymous = FALSE
GROUP BY
    event_user_id,
    wiki_db,
    IF(ARRAY_CONTAINS(revision_tags, 'discussiontools'), 'reply-tool', 'non-reply-tool') 
),
--find users that are blocked sitewide
blocked_users AS (
SELECT 
    h1.user_id AS blocked_user,
    h1.wiki_db AS blocked_wiki,
    min(h1.start_timestamp) AS block_time 
FROM(
    SELECT *
    FROM wmf.mediawiki_user_history
WHERE 
    snapshot = '2021-03'
    AND start_timestamp BETWEEN '2021-02-12' AND '2021-03-09'
    AND wiki_db IN ('frwiki', 'eswiki', 'itwiki', 'jawiki', 'fawiki', 'plwiki', 'hewiki', 'nlwiki',
    'hiwiki', 'kowiki', 'viwiki', 'thwiki', 'ptwiki', 'bnwiki', 'arzwiki', 'swwiki', 'zhwiki',
    'ukwiki', 'idwiki', 'amwiki', 'omwiki', 'afwiki')
    AND caused_by_event_type = 'alterblocks'
    AND inferred_from IS NULL) as h1
LEFT JOIN (
SELECT * FROM wmf.mediawiki_user_history
    WHERE 
    snapshot = '2021-03'
    AND end_timestamp BETWEEN '2021-02-12' AND '2021-03-09'
    AND wiki_db IN ('frwiki', 'eswiki', 'itwiki', 'jawiki', 'fawiki', 'plwiki', 'hewiki', 'nlwiki',
    'hiwiki', 'kowiki', 'viwiki', 'thwiki', 'ptwiki', 'bnwiki', 'arzwiki', 'swwiki', 'zhwiki',
    'ukwiki', 'idwiki', 'amwiki', 'omwiki', 'afwiki')
    AND caused_by_event_type = 'alterblocks'
    AND inferred_from IS NULL) AS h2
ON (h1.wiki_db = h2.wiki_db
    AND h1.user_id = h2.user_id
    AND h1.start_timestamp = h2.end_timestamp)
WHERE h2.start_timestamp IS NULL
GROUP BY h1.wiki_db, h1.user_id
)

-- Main Query --
SELECT
    wiki AS wiki,
    experience_level AS experience_level,
    editing_interface AS editing_interface,
    SUM(CAST(blocked_user IS NOT NULL and first_reply_time < block_time AS int)) AS blocked_user,
    COUNT(*) AS all_users

FROM (
SELECT
    reply_users.first_reply_time,
    blocked_users.block_time,
    reply_users.wiki,
    blocked_users.blocked_user,
    reply_users.experience_level,
    reply_users.editing_interface
FROM reply_users
LEFT JOIN blocked_users ON 
    reply_users.user_id = blocked_users.blocked_user AND
    reply_users.wiki = blocked_users.blocked_wiki 
) sessions
GROUP BY
    wiki,
    experience_level,
    editing_interface
   
