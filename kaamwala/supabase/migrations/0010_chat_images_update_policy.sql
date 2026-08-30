-- KaamWala v2 — 0010: chat_images participant UPDATE policy.
-- Lets a participant overwrite their own upload path so a failed message
-- insert can retry with the same path (uploadBinary with upsert).
create policy chat_images_participant_update on storage.objects for update
  to authenticated
  using (
    bucket_id = 'chat_images'
    and (storage.foldername(name))[1] = 'chat'
    and public.is_booking_participant((storage.foldername(name))[2]::uuid)
  );
