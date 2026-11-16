package kz.quickbites.feedback;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FeedbackRepository extends JpaRepository<Feedback, UUID> {
    Optional<Feedback> findByOrderId(UUID orderId);
    boolean existsByOrderId(UUID orderId);
    List<Feedback> findByOrderBuffetIdOrderByCreatedAtDesc(UUID buffetId);
}
