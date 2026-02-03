/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const { getMessaging } = require("firebase-admin/messaging");

// 리전 설정 (Firestore 위치와 일치시켜야 함)
setGlobalOptions({ region: "asia-northeast3" });

admin.initializeApp();

/**
 * [관리자 기능] 긴급 공지 푸시 알림 발송
 * notices 컬렉션 문서의 'push_requested' 필드가 true로 변경되면 실행
 */
exports.sendNoticePush = onDocumentUpdated("notices/{noticeId}", async (event) => {
  const newData = event.data.after.data();
  const oldData = event.data.before.data();

  // push_requested가 false -> true로 바뀐 경우에만 실행
  if (newData.push_requested === true && oldData.push_requested !== true) {

    const title = newData.title || "긴급 공지";
    const category = newData.category || "전체";
    const noticeId = event.params.noticeId;

    console.log(`🚀 푸시 요청 감지: [${category}] ${title}`);

    // 메시지 구성 (주제 구독 방식)
    const message = {
      notification: {
        title: `[${category}] 새 공지`,
        body: title,
      },
      data: {
        noticeId: noticeId,
        category: category,
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      },
      topic: "notice" // 'notice' 주제를 구독한 모든 유저에게 발송
    };

    try {
      // 푸시 발송
      const response = await getMessaging().send(message);
      console.log("✅ 푸시 발송 성공:", response);

      // 처리 완료 플래그 업데이트 (무한 루프 방지)
      return event.data.after.ref.update({
        push_requested: false,
        push_sent_at: admin.firestore.FieldValue.serverTimestamp(),
        push_status: "SUCCESS"
      });

    } catch (error) {
      console.error("❌ 푸시 발송 실패:", error);

      // 실패 상태 기록
      return event.data.after.ref.update({
        push_requested: false,
        push_status: "FAILED",
        push_error: error.message
      });
    }
  }

  return null;
});
