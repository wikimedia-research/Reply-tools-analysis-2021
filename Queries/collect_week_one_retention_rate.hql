WITH first_edits AS (
-- users that made an attempt during the AB Test
    SELECT
        event_user_text as user_name,
        wiki_db AS wiki,
        min(event_timestamp) as first_edit_time,
        CASE
        WHEN min(event_user_revision_count) is NULL THEN 'undefined'
        WHEN min(event_user_revision_count) < 100 THEN 'junior'
        ELSE 'non-junior'
        END AS experience_level,
        IF(ARRAY_CONTAINS(revision_tags, 'discussiontools'), 'reply-tool', 'non-reply-tool') AS editing_interface
    FROM wmf.mediawiki_history 
    WHERE
        snapshot = '2021-03'
        AND event_timestamp >= '2021-02-12' 
        AND event_timestamp < '2021-03-10'
    -- do not include new discussion tool talk page edits
        AND NOT (ARRAY_CONTAINS(revision_tags, 'discussiontools-newtopic'))
    -- include only desktop edits
        AND NOT array_contains(revision_tags, 'iOS')
        AND NOT array_contains(revision_tags, 'Android')
        AND NOT array_contains(revision_tags, 'Mobile Web')
        -- first edit not reverted within 48 hours
        AND NOT (revision_is_identity_reverted AND 
            revision_seconds_to_identity_revert <= 172800)  -- 48 hours
     -- find all edits on talk pages
        AND page_namespace_historical % 2 = 1
        AND event_entity = 'revision'
        AND event_type = 'create'
         -- on all participating wikis
        AND wiki_db IN ('frwiki', 'eswiki', 'itwiki', 'jawiki', 'fawiki', 'plwiki', 'hewiki', 'nlwiki',
    'hiwiki', 'kowiki', 'viwiki', 'thwiki', 'ptwiki', 'bnwiki', 'arzwiki', 'swwiki', 'zhwiki',
    'ukwiki', 'idwiki', 'amwiki', 'omwiki', 'afwiki')
    -- user is not a bot and not anonymous
         AND SIZE(event_user_is_bot_by_historical) = 0 
         AND SIZE(event_user_is_bot_by) = 0
        AND event_user_is_anonymous = FALSE
    GROUP BY event_user_text,
    IF(ARRAY_CONTAINS(revision_tags, 'discussiontools'), 'reply-tool', 'non-reply-tool'),
    wiki_db
)
 
SELECT
    first_edits.experience_level,
    first_edits.editing_interface,
    (count(first_week.user_name)/count(*)) as first_week_retention_rate
FROM first_edits
LEFT JOIN
(
    SELECT event_user_text as user_name,
    first_edits.first_edit_time,
    min(event_timestamp) as return_time
    FROM wmf.mediawiki_history mh
    INNER JOIN first_edits
    ON mh.event_user_text = first_edits.user_name
    WHERE
        snapshot = '2021-03'
    -- do not include new discussion tool talk page edits
        AND NOT (ARRAY_CONTAINS(revision_tags, 'discussiontools-newtopic'))
    -- include only desktop edits
        AND NOT array_contains(revision_tags, 'iOS')
        AND NOT array_contains(revision_tags, 'Android')
        AND NOT array_contains(revision_tags, 'Mobile Web')
     -- find all edits on talk pages
        AND page_namespace_historical % 2 = 1
        AND event_entity = 'revision'
        AND event_type = 'create'
         -- on all participating wikis
        AND wiki_db IN ('frwiki', 'eswiki', 'itwiki', 'jawiki', 'fawiki', 'plwiki', 'hewiki', 'nlwiki',
    'hiwiki', 'kowiki', 'viwiki', 'thwiki', 'ptwiki', 'bnwiki', 'arzwiki', 'swwiki', 'zhwiki',
    'ukwiki', 'idwiki', 'amwiki', 'omwiki', 'afwiki')
    -- return edit not reverted within 48 hours
        AND NOT (revision_is_identity_reverted AND 
            revision_seconds_to_identity_revert <= 172800)  -- 48 hours
    -- user is not a bot and not anonymous
         AND SIZE(event_user_is_bot_by_historical) = 0 
         AND SIZE(event_user_is_bot_by) = 0
        AND event_user_is_anonymous = FALSE
        AND first_edits.first_edit_time >=  '2021-02-12'  
        AND first_edits.first_edit_time  < '2021-03-10' 
        -- second revision is between two and 8 days
        AND unix_timestamp(event_timestamp, 'yyyy-MM-dd HH:mm:ss.0') >=
            (unix_timestamp(first_edits.first_edit_time, 'yyyy-MM-dd HH:mm:ss.0') + (2*24*60*60)) 
        AND unix_timestamp(event_timestamp, 'yyyy-MM-dd HH:mm:ss.0') <=
            (unix_timestamp(first_edits.first_edit_time, 'yyyy-MM-dd HH:mm:ss.0') + (8*24*60*60))
    GROUP BY event_user_text, 
        first_edits.first_edit_time 
) AS first_week
ON 
(first_edits.user_name = first_week.user_name and
first_edits.first_edit_time = first_week.first_edit_time 
)
GROUP BY
    first_edits.experience_level,
    first_edits.editing_interface;