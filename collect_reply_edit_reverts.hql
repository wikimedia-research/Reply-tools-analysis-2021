SELECT
     wiki_db AS wiki,
     event_user_id AS user_id,
      CASE
        WHEN min(event_user_revision_count) is NULL THEN 'undefined'
        WHEN min(event_user_revision_count) < 100 THEN 'junior'
        ELSE 'non-junior'
        END AS experience_level,
    IF(ARRAY_CONTAINS(revision_tags, 'discussiontools'), 'reply-tool', 'non-reply-tool') AS editing_interface,
     SUM(CAST(
            revision_is_identity_reverted AND 
            revision_seconds_to_identity_revert <= 172800  -- 48 hours
           AS int)) AS num_reverts,
    COUNT(*) as num_comments
FROM wmf.mediawiki_history 
WHERE 
    snapshot = '2021-02'
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
    -- dates of the AB Test within Feb
    AND event_timestamp >= '2021-02-12' 
    AND event_timestamp < '2021-02-28'
    -- on all participating wikis
    AND wiki_db IN ('frwiki', 'eswiki', 'itwiki', 'jawiki', 'fawiki', 'plwiki', 'hewiki', 'nlwiki',
    'hiwiki', 'kowiki', 'viwiki', 'thwiki', 'ptwiki', 'bnwiki', 'arzwiki', 'swwiki', 'zhwiki',
    'ukwiki', 'idwiki', 'amwiki', 'omwiki', 'afwiki')
    -- user is not a bot and not anonymous
    AND SIZE(event_user_is_bot_by_historical) = 0 
    AND SIZE(event_user_is_bot_by) = 0
    AND event_user_is_anonymous = FALSE
GROUP BY 
 wiki_db,
 event_user_id,
 IF(ARRAY_CONTAINS(revision_tags, 'discussiontools'), 'reply-tool', 'non-reply-tool')
