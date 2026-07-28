package com.moonlighttalk.server.common.storage;

/** S3 / 로컬 디스크 추상화(05 문서 §8). 컨트롤러/서비스는 이 인터페이스만 의존. */
public interface FileStorageService {

    /** 업로드 대상 URL 발급(S3=presigned PUT, 로컬=서버 업로드 엔드포인트). */
    String issueUploadUrl(String key, String contentType);

    /** 다운로드 URL 발급(S3=짧은 TTL presigned GET, 로컬=서버 다운로드 엔드포인트). */
    String issueDownloadUrl(String key);

    void delete(String key);
}
