package com.mybudget.backend.service;

import com.mybudget.backend.config.AuthContext;
import com.mybudget.backend.domain.*;
import com.mybudget.backend.dto.FavoriteTransactionDto;
import com.mybudget.backend.exception.NotFoundException;
import com.mybudget.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FavoriteTransactionService {

    private final FavoriteTransactionRepository repo;
    private final AccountRepository accountRepo;
    private final CategoryRepository categoryRepo;

    public List<FavoriteTransactionDto.Response> findAll() {
        User user = AuthContext.requireUser();
        return repo.findByUserIdOrderBySortOrderAsc(user.getId()).stream()
                .map(FavoriteTransactionDto.Response::from).toList();
    }

    @Transactional
    public FavoriteTransactionDto.Response create(FavoriteTransactionDto.CreateRequest req) {
        User user = AuthContext.requireUser();
        Account account = accountRepo.findByIdAndUserId(req.accountId(), user.getId())
                .orElseThrow(() -> new NotFoundException("Account", req.accountId()));
        Category category = req.categoryId() != null
                ? categoryRepo.findByIdAndUserId(req.categoryId(), user.getId())
                    .orElseThrow(() -> new NotFoundException("Category", req.categoryId()))
                : null;
        FavoriteTransaction f = FavoriteTransaction.builder()
                .user(user)
                .label(req.label()).kind(req.kind()).amount(req.amount())
                .account(account).category(category).memo(req.memo()).sortOrder(0).build();
        return FavoriteTransactionDto.Response.from(repo.save(f));
    }

    @Transactional
    public void delete(Long id) {
        User user = AuthContext.requireUser();
        FavoriteTransaction favorite = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("FavoriteTransaction", id));
        repo.delete(favorite);
    }
}
