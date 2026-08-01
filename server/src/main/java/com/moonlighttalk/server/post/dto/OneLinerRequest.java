package com.moonlighttalk.server.post.dto;

import jakarta.validation.constraints.Size;

/** 하루 한 마디(최대 25자, 1건만 유지하며 갱신). */
public record OneLinerRequest(@Size(max = 25) String oneLiner) {
}
