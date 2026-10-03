package org.acme.mapping;

import org.acme.domain.Store;
import org.acme.dto.StoreDTO;

public final class StoreMapper {
  private StoreMapper() {}

  public static StoreDTO map(Store store) {
    if (store == null) {
      return null;
    }

    return new StoreDTO(
        store.getId(),
        store.getName(),
        store.getCurrency(),
        AddressMapper.map(store.getAddress())
    );
  }

  public static Store map(StoreDTO storeDTO) {
    return (storeDTO != null) ?
        new Store(null, storeDTO.name(), AddressMapper.map(storeDTO.address()), storeDTO.currency()) :
        null;
  }
}
