
package kz.quickbites.notification;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NotificationRepository
        extends JpaRepository<Notification, UUID> {

    List<Notification> findByUserEmailIgnoreCaseOrderByCreatedAtDesc(
            String email
    );

    Optional<Notification> findByIdAndUserEmailIgnoreCase(
            UUID id,
            String email
    );

    long countByUserEmailIgnoreCaseAndReadFalse(
            String email
    );

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
        update Notification n
        set n.read = true
        where lower(n.user.email) = lower(:email)
          and n.read = false
        """)
    int markAllRead(
            @Param("email") String email
    );
}
