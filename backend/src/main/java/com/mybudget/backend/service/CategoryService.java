package com.mybudget.backend.service;

import com.mybudget.backend.config.AuthContext;
import com.mybudget.backend.domain.Category;
import com.mybudget.backend.domain.CategoryKind;
import com.mybudget.backend.domain.User;
import com.mybudget.backend.dto.CategoryDto;
import com.mybudget.backend.exception.NotFoundException;
import com.mybudget.backend.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CategoryService {

    private final CategoryRepository repo;

    public List<CategoryDto.Response> findByKind(CategoryKind kind) {
        User user = AuthContext.requireUser();
        return repo.findByUserIdAndKindAndArchivedFalseOrderBySortOrderAsc(user.getId(), kind).stream()
                .map(CategoryDto.Response::from).toList();
    }

    public List<CategoryDto.Response> findAll() {
        User user = AuthContext.requireUser();
        return repo.findByUserIdAndArchivedFalseOrderBySortOrderAsc(user.getId()).stream()
                .map(CategoryDto.Response::from).toList();
    }

    @Transactional
    public CategoryDto.Response create(CategoryDto.CreateRequest req) {
        User user = AuthContext.requireUser();
        Category parent = req.parentId() != null
                ? repo.findByIdAndUserId(req.parentId(), user.getId())
                    .orElseThrow(() -> new NotFoundException("Category", req.parentId()))
                : null;
        Category c = Category.builder()
                .user(user)
                .name(req.name()).kind(req.kind()).parent(parent)
                .icon(req.icon()).color(req.color())
                .sortOrder(req.sortOrder() != null ? req.sortOrder() : 0)
                .archived(false).build();
        return CategoryDto.Response.from(repo.save(c));
    }

    @Transactional
    public CategoryDto.Response update(Long id, CategoryDto.UpdateRequest req) {
        User user = AuthContext.requireUser();
        Category c = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("Category", id));
        c.setName(req.name());
        if (req.icon() != null) c.setIcon(req.icon());
        if (req.color() != null) c.setColor(req.color());
        if (req.sortOrder() != null) c.setSortOrder(req.sortOrder());
        if (req.archived() != null) c.setArchived(req.archived());
        return CategoryDto.Response.from(c);
    }

    @Transactional
    public void delete(Long id) {
        User user = AuthContext.requireUser();
        Category category = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("Category", id));
        repo.delete(category);
    }
}
