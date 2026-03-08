-- Ensure parent can insert own care_teams row right after creating a child.
-- This fixes create-child flow failing with:
-- "new row violates row-level security policy for table care_teams".

DROP POLICY IF EXISTS care_teams_owner_insert ON public.care_teams;

CREATE POLICY care_teams_owner_insert ON public.care_teams
FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.children c
    WHERE c.id = care_teams.child_id
      AND c.created_by = auth.uid()
  )
);
