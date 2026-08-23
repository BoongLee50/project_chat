-- 음성 메시지 (기획: 대화방 음성 녹음·전송·재생)
--
-- 텍스트와 같은 chat_messages에 담는다. 별도 테이블로 나누면 대화 순서를 맞추려고
-- 매번 두 테이블을 합쳐야 하고, 읽음 처리·보관 만료(FIFO 삭제)도 두 벌이 된다.
--
-- 오디오 파일 자체는 스토리지에 두고 여기에는 key만 남긴다(사진과 같은 방식).
-- 재생 길이는 파일을 열지 않고도 목록에서 바로 보여줘야 해서 함께 저장한다.

ALTER TABLE chat_messages
    ADD COLUMN type ENUM('TEXT','VOICE') NOT NULL DEFAULT 'TEXT'
        COMMENT '메시지 종류. VOICE면 body는 비고 audio_* 를 쓴다' AFTER sender_id,
    ADD COLUMN audio_key VARCHAR(255) NULL
        COMMENT '스토리지 key. TEXT면 NULL' AFTER body,
    ADD COLUMN audio_duration_ms INT NULL
        COMMENT '녹음 길이(ms). 파일을 열지 않고 목록에 표시하려고 저장' AFTER audio_key;

-- 음성 메시지는 본문이 없다. NOT NULL을 유지하되 기본값을 둬 INSERT를 단순하게 만든다.
ALTER TABLE chat_messages
    MODIFY COLUMN body VARCHAR(500) NOT NULL DEFAULT '';
