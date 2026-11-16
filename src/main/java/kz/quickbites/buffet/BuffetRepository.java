package kz.quickbites.buffet;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BuffetRepository extends JpaRepository<Buffet, UUID> {
    @EntityGraph(attributePaths = "owner")
    List<Buffet> findAllByOrderByNameAsc();
    @EntityGraph(attributePaths = "owner")
    List<Buffet> findByOwnerEmailIgnoreCase(String email);
}
