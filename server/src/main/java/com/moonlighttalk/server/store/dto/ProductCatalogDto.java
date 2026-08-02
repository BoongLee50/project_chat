package com.moonlighttalk.server.store.dto;

import java.util.List;

/** 상품 카탈로그. 현금 가격은 스토어 SDK의 현지 가격을 쓰고, 여기서는 구성·혜택만 준다. */
public record ProductCatalogDto(
        List<LunaProductDto> lunaProducts,
        List<LunaPackDto> lunaPacks,
        List<PrimePlanDto> primePlans
) {
}
