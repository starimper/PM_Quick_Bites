package kz.quickbites.menu;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MenuRepository extends JpaRepository<Menu, UUID> {
    Optional<Menu> findByBuffetIdAndMenuDate(UUID buffetId, LocalDate menuDate);
}
