package kz.quickbites.common;

import java.net.URI;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiExceptionHandler {
    @ExceptionHandler(ApiException.class)
    ProblemDetail handleApi(ApiException ex) {
        ProblemDetail detail = ProblemDetail.forStatusAndDetail(ex.getStatus(), ex.getMessage());
        detail.setTitle(ex.getStatus().getReasonPhrase());
        detail.setType(URI.create("https://quickbites.local/problems/" + ex.getStatus().value()));
        return detail;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ProblemDetail handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = ex.getBindingResult().getFieldErrors().stream()
                .collect(java.util.stream.Collectors.toMap(
                        error -> error.getField(),
                        error -> error.getDefaultMessage() == null ? "Invalid value" : error.getDefaultMessage(),
                        (first, ignored) -> first));
        ProblemDetail detail = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Request validation failed");
        detail.setTitle("Validation failed");
        detail.setProperty("errors", errors);
        return detail;
    }

    @ExceptionHandler({DataIntegrityViolationException.class, ObjectOptimisticLockingFailureException.class})
    ProblemDetail handleConflict(Exception ex) {
        ProblemDetail detail = ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT,
                "The request conflicts with a concurrent update or an existing record");
        detail.setTitle(HttpStatus.CONFLICT.getReasonPhrase());
        detail.setType(URI.create("https://quickbites.local/problems/409"));
        return detail;
    }
}
