-- =============================================
-- SEED DATA — Development & Testing
-- AppPickleball Database
-- =============================================
-- Chạy SAU create_pickleball_database.sql
-- Password cho tất cả users: Admin@123 (bcrypt hash)

-- Hash cho "Admin@123" với bcrypt cost=12:
-- $2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4tbQLokQRW

-- =============================================
-- USERS
-- =============================================

INSERT INTO users (id, email, password_hash, name, avatar_url, bio, skill_level, dominant_hand, is_email_verified, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'admin@test.com',   '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4tbQLokQRW', 'Admin User',      NULL,  'Quản trị viên hệ thống',     3.5, 'right', true,  NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
  (gen_random_uuid(), 'creator@test.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4tbQLokQRW', 'Creator Test',    NULL,  'Người tạo giải đấu mẫu',    4.0, 'right', true,  NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
  (gen_random_uuid(), 'player1@test.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4tbQLokQRW', 'Nguyễn Văn A',    NULL,  'Tay vợt trái Hà Nội',       3.0, 'right', true,  NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
  (gen_random_uuid(), 'player2@test.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4tbQLokQRW', 'Trần Thị B',      NULL,  'Chuyên đấu đôi',             3.5, 'left',  true,  NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
  (gen_random_uuid(), 'player3@test.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4tbQLokQRW', 'Lê Văn C',        NULL,  NULL,                         2.5, 'right', true,  NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
  (gen_random_uuid(), 'player4@test.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4tbQLokQRW', 'Phạm Thị D',      NULL,  'Mới bắt đầu chơi',          2.0, 'right', true,  NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
  (gen_random_uuid(), 'player5@test.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4tbQLokQRW', 'Hoàng Văn E',     NULL,  'Intermediate player',       3.5, 'right', true,  NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
  (gen_random_uuid(), 'player6@test.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4tbQLokQRW', 'Vũ Thị F',        NULL,  NULL,                         4.5, 'left',  true,  NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');

-- Lưu user IDs vào biến tạm để dùng ở dưới
DO $$
DECLARE
  v_creator_id   UUID;
  v_player1_id   UUID;
  v_player2_id   UUID;
  v_player3_id   UUID;
  v_player4_id   UUID;
  v_tournament_id UUID;
  v_group_id     UUID;
  v_member1_id   UUID;
  v_member2_id   UUID;
  v_member3_id   UUID;
  v_member4_id   UUID;
BEGIN
  SELECT id INTO v_creator_id FROM users WHERE email = 'creator@test.com';
  SELECT id INTO v_player1_id FROM users WHERE email = 'player1@test.com';
  SELECT id INTO v_player2_id FROM users WHERE email = 'player2@test.com';
  SELECT id INTO v_player3_id FROM users WHERE email = 'player3@test.com';
  SELECT id INTO v_player4_id FROM users WHERE email = 'player4@test.com';

  -- =============================================
  -- TOURNAMENT (completed, singles, 1 bảng)
  -- =============================================

  INSERT INTO tournaments (id, creator_id, name, description, type, num_groups, scoring_format, status, date, location, created_at, updated_at)
  VALUES (
    gen_random_uuid(),
    v_creator_id,
    'Giải Thi Đấu Mẫu #1',
    'Giải đấu mẫu để test hệ thống',
    'singles',
    1,
    'best_of_3',
    'completed',
    CURRENT_DATE - INTERVAL '7 days',
    'Sân Pickleball Test, 123 Đường ABC, Hà Nội',
    NOW() AT TIME ZONE 'UTC',
    NOW() AT TIME ZONE 'UTC'
  ) RETURNING id INTO v_tournament_id;

  -- Participants (4 người, bảng A)
  INSERT INTO participants (id, tournament_id, user_id, status, joined_at, created_at, updated_at)
  VALUES
    (gen_random_uuid(), v_tournament_id, v_creator_id, 'confirmed', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (gen_random_uuid(), v_tournament_id, v_player1_id, 'confirmed', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (gen_random_uuid(), v_tournament_id, v_player2_id, 'confirmed', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (gen_random_uuid(), v_tournament_id, v_player3_id, 'confirmed', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');

  -- Group A
  INSERT INTO groups (id, tournament_id, name, display_order, created_at, updated_at)
  VALUES (gen_random_uuid(), v_tournament_id, 'A', 1, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
  RETURNING id INTO v_group_id;

  -- Group Members (seed 1=creator, 2=player1, 3=player2, 4=player3)
  INSERT INTO group_members (id, group_id, player_id, team_id, seed_order, created_at)
  VALUES
    (gen_random_uuid(), v_group_id, v_creator_id, NULL, 1, NOW() AT TIME ZONE 'UTC'),
    (gen_random_uuid(), v_group_id, v_player1_id, NULL, 2, NOW() AT TIME ZONE 'UTC'),
    (gen_random_uuid(), v_group_id, v_player2_id, NULL, 3, NOW() AT TIME ZONE 'UTC'),
    (gen_random_uuid(), v_group_id, v_player3_id, NULL, 4, NOW() AT TIME ZONE 'UTC');

  -- 6 Matches Round Robin (creator=P1, player1=P2, player2=P3, player3=P4)
  -- Round 1: P1 vs P2, P3 vs P4
  INSERT INTO matches (id, tournament_id, group_id, round, match_order, player1_id, player2_id, player1_scores, player2_scores, winner_id, status, created_at, updated_at)
  VALUES
    -- Round 1
    (gen_random_uuid(), v_tournament_id, v_group_id, 1, 1, v_creator_id, v_player1_id, '[11, 9, 11]'::jsonb, '[7, 11, 8]'::jsonb, v_creator_id, 'completed', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (gen_random_uuid(), v_tournament_id, v_group_id, 1, 2, v_player2_id, v_player3_id, '[11, 11]'::jsonb, '[5, 8]'::jsonb,   v_player2_id, 'completed', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    -- Round 2
    (gen_random_uuid(), v_tournament_id, v_group_id, 2, 1, v_creator_id, v_player2_id, '[11, 8, 11]'::jsonb, '[9, 11, 6]'::jsonb, v_creator_id, 'completed', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (gen_random_uuid(), v_tournament_id, v_group_id, 2, 2, v_player1_id, v_player3_id, '[11, 11]'::jsonb, '[6, 7]'::jsonb,   v_player1_id, 'completed', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    -- Round 3
    (gen_random_uuid(), v_tournament_id, v_group_id, 3, 1, v_creator_id, v_player3_id, '[11, 11]'::jsonb, '[3, 4]'::jsonb,   v_creator_id, 'completed', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (gen_random_uuid(), v_tournament_id, v_group_id, 3, 2, v_player1_id, v_player2_id, '[11, 9, 11]'::jsonb, '[8, 11, 7]'::jsonb, v_player1_id, 'completed', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');

  -- =============================================
  -- TOURNAMENT (open, singles, đang nhận đăng ký)
  -- =============================================

  INSERT INTO tournaments (id, creator_id, name, description, type, num_groups, scoring_format, status, date, location, created_at, updated_at)
  VALUES (
    gen_random_uuid(),
    v_creator_id,
    'Giải Mùa Xuân 2026',
    'Giải đấu đang mở đăng ký, cần thêm người',
    'singles',
    1,
    'best_of_3',
    'open',
    CURRENT_DATE + INTERVAL '14 days',
    'Sân Pickleball Mùa Xuân, 456 Đường XYZ, TP.HCM',
    NOW() AT TIME ZONE 'UTC',
    NOW() AT TIME ZONE 'UTC'
  );

END $$;

-- =============================================
-- NOTIFICATIONS (mẫu)
-- =============================================

INSERT INTO notifications (id, user_id, type, title, body, data, is_read, created_at)
SELECT
  gen_random_uuid(),
  u.id,
  'tournament_invite',
  'Bạn được mời vào giải đấu',
  'Creator Test mời bạn tham gia Giải Mùa Xuân 2026',
  '{"screen":"tournament","id":1}'::jsonb,
  false,
  NOW() AT TIME ZONE 'UTC'
FROM users u
WHERE u.email IN ('player1@test.com', 'player2@test.com');

-- =============================================
-- VERIFY
-- =============================================

-- Chạy các query này để verify seed data OK:
-- SELECT COUNT(*) FROM users;          -- 7
-- SELECT COUNT(*) FROM tournaments;    -- 2
-- SELECT COUNT(*) FROM matches;        -- 6
-- SELECT COUNT(*) FROM notifications;  -- 2
-- SELECT email, name, skill_level FROM users ORDER BY created_at;
