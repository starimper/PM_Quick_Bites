package kz.quickbites.menu;

import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MealRepository extends JpaRepository<Meal, UUID> {
    List<Meal> findByMenuIdOrderByNameAsc(UUID menuId);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select m from Meal m where m.id = :id")
    Optional<Meal> findLockedById(@Param("id") UUID id);
}
