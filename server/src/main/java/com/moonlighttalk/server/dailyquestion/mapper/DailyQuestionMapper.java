package com.moonlighttalk.server.dailyquestion.mapper;

import com.moonlighttalk.server.dailyquestion.entity.DailyAnswer;
import com.moonlighttalk.server.dailyquestion.entity.DailyQuestion;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.util.List;

@Mapper
public interface DailyQuestionMapper {

    DailyQuestion selectQuestionByDate(@Param("sessionDate") LocalDate sessionDate);

    /**
     * 후보에서 <b>아직 안 쓴 질문</b>을 하나. 다 썼으면 가장 오래전에 쓴 것을 다시 준다.
     * 질문이 떨어져도 이벤트가 멈추지 않게 하기 위함이다.
     */
    DailyQuestion selectUnusedFromBank();

    /** 같은 날짜가 이미 있으면 무시(동시 요청이 겹쳐도 질문이 둘이 되지 않게). */
    int insertQuestion(DailyQuestion question);

    int countAnswers(@Param("questionId") String questionId);

    DailyAnswer selectMyAnswer(@Param("questionId") String questionId,
                                @Param("userId") String userId);

    DailyAnswer selectAnswerById(@Param("answerId") String answerId,
                                  @Param("viewerId") String viewerId);

    /**
     * 목록. 정렬은 최신순 또는 <b>인기순(좋아요+댓글 합)</b>.
     * 차단·신고한 상대는 제외한다(가든과 같은 규칙).
     */
    List<DailyAnswer> selectAnswers(@Param("questionId") String questionId,
                                     @Param("viewerId") String viewerId,
                                     @Param("sort") String sort,
                                     @Param("offset") int offset,
                                     @Param("limit") int limit);

    void insertAnswer(DailyAnswer answer);

    /** 좋아요 — 이미 눌렀으면 아무 일도 없다(사람마다 한 번). */
    int insertLike(@Param("answerId") String answerId, @Param("userId") String userId);

    /** 지난 영업일 답변 정리(질문과 좋아요는 FK로 함께 지워진다). */
    int deleteAnswersBefore(@Param("sessionDate") LocalDate sessionDate);
}
