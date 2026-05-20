package com.mybudget.backend.service;

import com.mybudget.backend.domain.*;
import com.mybudget.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserDataInitializer {

    private final AccountRepository accountRepo;
    private final CategoryRepository categoryRepo;
    private final TagRepository tagRepo;
    private final TransactionRepository transactionRepo;
    private final TransferRepository transferRepo;
    private final BudgetRepository budgetRepo;
    private final RecurringRuleRepository recurringRuleRepo;
    private final SavingsGoalRepository savingsGoalRepo;
    private final FavoriteTransactionRepository favoriteTransactionRepo;
    private final MerchantRuleRepository merchantRuleRepo;

    @Transactional
    public void ensureUserData(User user) {
        if (user == null || user.getId() == null) {
            return;
        }

        claimLegacyRowsIfThisIsAFreshUser(user);

        if (accountRepo.countByUserId(user.getId()) == 0) {
            createDefaultAccounts(user);
        }
        if (categoryRepo.countByUserId(user.getId()) == 0) {
            createDefaultCategories(user);
        }
        if (merchantRuleRepo.countByUserId(user.getId()) == 0) {
            createDefaultMerchantRules(user);
        }
        normalizeCardBalances(user);
    }

    private void claimLegacyRowsIfThisIsAFreshUser(User user) {
        if (accountRepo.countByUserId(user.getId()) > 0 || categoryRepo.countByUserId(user.getId()) > 0) {
            return;
        }

        List<Account> accounts = accountRepo.findByUserIsNullOrderBySortOrderAsc();
        List<Category> categories = categoryRepo.findByUserIsNullOrderBySortOrderAsc();
        List<Tag> tags = tagRepo.findByUserIsNull();
        List<Transaction> transactions = transactionRepo.findByUserIsNull();
        List<Transfer> transfers = transferRepo.findByUserIsNull();
        List<Budget> budgets = budgetRepo.findByUserIsNull();
        List<RecurringRule> recurringRules = recurringRuleRepo.findByUserIsNull();
        List<SavingsGoal> savingsGoals = savingsGoalRepo.findByUserIsNull();
        List<FavoriteTransaction> favorites = favoriteTransactionRepo.findByUserIsNull();
        List<MerchantRule> merchantRules = merchantRuleRepo.findByUserIsNullOrderByPriorityDesc();

        boolean hasLegacyRows = !accounts.isEmpty() || !categories.isEmpty() || !tags.isEmpty()
                || !transactions.isEmpty() || !transfers.isEmpty() || !budgets.isEmpty()
                || !recurringRules.isEmpty() || !savingsGoals.isEmpty() || !favorites.isEmpty()
                || !merchantRules.isEmpty();
        if (!hasLegacyRows) {
            return;
        }

        accounts.forEach(a -> a.setUser(user));
        categories.forEach(c -> c.setUser(user));
        tags.forEach(t -> t.setUser(user));
        transactions.forEach(t -> t.setUser(user));
        transfers.forEach(t -> t.setUser(user));
        budgets.forEach(b -> b.setUser(user));
        recurringRules.forEach(r -> r.setUser(user));
        savingsGoals.forEach(g -> g.setUser(user));
        favorites.forEach(f -> f.setUser(user));
        merchantRules.forEach(m -> m.setUser(user));
    }

    private void createDefaultAccounts(User user) {
        accountRepo.saveAll(List.of(
                Account.builder()
                        .user(user)
                        .name("현금 지갑")
                        .type(AccountType.CASH)
                        .balance(0L)
                        .currency("KRW")
                        .color("#64748b")
                        .sortOrder(1)
                        .archived(false)
                        .build(),
                Account.builder()
                        .user(user)
                        .name("주거래 은행")
                        .type(AccountType.DEPOSIT)
                        .balance(0L)
                        .currency("KRW")
                        .color("#0ea5e9")
                        .sortOrder(2)
                        .archived(false)
                        .build()
        ));
    }

    private void normalizeCardBalances(User user) {
        accountRepo.findByUserIdAndTypeAndArchivedFalse(user.getId(), AccountType.CHECK_CARD)
                .forEach(account -> account.setBalance(0L));
        accountRepo.findByUserIdAndTypeAndArchivedFalse(user.getId(), AccountType.CREDIT_CARD)
                .forEach(account -> account.setBalance(0L));
    }

    private void createDefaultCategories(User user) {
        categoryRepo.saveAll(List.of(
                category(user, "식비", CategoryKind.EXPENSE, "utensils", "#ef4444", 1),
                category(user, "카페/간식", CategoryKind.EXPENSE, "coffee", "#f97316", 2),
                category(user, "교통", CategoryKind.EXPENSE, "bus", "#eab308", 3),
                category(user, "통신", CategoryKind.EXPENSE, "wifi", "#84cc16", 4),
                category(user, "주거/관리비", CategoryKind.EXPENSE, "home", "#22c55e", 5),
                category(user, "의료/건강", CategoryKind.EXPENSE, "heart-pulse", "#10b981", 6),
                category(user, "교육/자기계발", CategoryKind.EXPENSE, "book-open", "#14b8a6", 7),
                category(user, "쇼핑/생활용품", CategoryKind.EXPENSE, "shopping-bag", "#06b6d4", 8),
                category(user, "의류/미용", CategoryKind.EXPENSE, "shirt", "#0ea5e9", 9),
                category(user, "여가/문화", CategoryKind.EXPENSE, "film", "#3b82f6", 10),
                category(user, "경조사", CategoryKind.EXPENSE, "gift", "#6366f1", 11),
                category(user, "보험", CategoryKind.EXPENSE, "shield", "#8b5cf6", 12),
                category(user, "세금/공과금", CategoryKind.EXPENSE, "receipt", "#a855f7", 13),
                category(user, "기부", CategoryKind.EXPENSE, "hand-heart", "#d946ef", 14),
                category(user, "기타 지출", CategoryKind.EXPENSE, "more-horizontal", "#64748b", 15),
                category(user, "월급", CategoryKind.INCOME, "wallet", "#16a34a", 1),
                category(user, "보너스/상여", CategoryKind.INCOME, "sparkles", "#22c55e", 2),
                category(user, "부수입", CategoryKind.INCOME, "briefcase", "#10b981", 3),
                category(user, "용돈", CategoryKind.INCOME, "hand-coins", "#14b8a6", 4),
                category(user, "이자/배당", CategoryKind.INCOME, "trending-up", "#06b6d4", 5),
                category(user, "기타 수입", CategoryKind.INCOME, "plus-circle", "#64748b", 6)
        ));
    }

    private Category category(User user, String name, CategoryKind kind, String icon, String color, int sortOrder) {
        return Category.builder()
                .user(user)
                .name(name)
                .kind(kind)
                .icon(icon)
                .color(color)
                .sortOrder(sortOrder)
                .archived(false)
                .build();
    }

    private void createDefaultMerchantRules(User user) {
        Map<String, Category> categories = categoryRepo
                .findByUserIdAndArchivedFalseOrderBySortOrderAsc(user.getId())
                .stream()
                .collect(Collectors.toMap(Category::getName, Function.identity(), (a, b) -> a));

        List<MerchantRuleSeed> seeds = List.of(
                rule("스타벅스", "카페/간식", 100), rule("이디야", "카페/간식", 100),
                rule("투썸", "카페/간식", 100), rule("메가커피", "카페/간식", 100),
                rule("컴포즈", "카페/간식", 100),
                rule("GS25", "식비", 100), rule("CU", "식비", 100),
                rule("세븐일레븐", "식비", 100), rule("이마트24", "식비", 100),
                rule("맥도날드", "식비", 100), rule("버거킹", "식비", 100),
                rule("롯데리아", "식비", 100), rule("배달의민족", "식비", 110),
                rule("쿠팡이츠", "식비", 110), rule("요기요", "식비", 110),
                rule("이마트", "쇼핑/생활용품", 100), rule("홈플러스", "쇼핑/생활용품", 100),
                rule("롯데마트", "쇼핑/생활용품", 100), rule("쿠팡", "쇼핑/생활용품", 95),
                rule("11번가", "쇼핑/생활용품", 95), rule("SSG", "쇼핑/생활용품", 95),
                rule("지하철", "교통", 100), rule("버스", "교통", 100),
                rule("택시", "교통", 100), rule("카카오T", "교통", 105),
                rule("티머니", "교통", 100), rule("SK텔레콤", "통신", 100),
                rule("KT", "통신", 100), rule("LGU+", "통신", 100),
                rule("넷플릭스", "여가/문화", 100), rule("유튜브", "여가/문화", 100),
                rule("CGV", "여가/문화", 100), rule("메가박스", "여가/문화", 100),
                rule("롯데시네마", "여가/문화", 100)
        );

        merchantRuleRepo.saveAll(seeds.stream()
                .filter(seed -> categories.containsKey(seed.categoryName()))
                .map(seed -> MerchantRule.builder()
                        .user(user)
                        .pattern(seed.pattern())
                        .category(categories.get(seed.categoryName()))
                        .priority(seed.priority())
                        .build())
                .toList());
    }

    private MerchantRuleSeed rule(String pattern, String categoryName, int priority) {
        return new MerchantRuleSeed(pattern, categoryName, priority);
    }

    private record MerchantRuleSeed(String pattern, String categoryName, int priority) {
    }
}
