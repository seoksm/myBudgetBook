package com.mybudget.backend.service;

import com.mybudget.backend.config.AuthContext;
import com.mybudget.backend.domain.Tag;
import com.mybudget.backend.domain.User;
import com.mybudget.backend.dto.TagDto;
import com.mybudget.backend.exception.NotFoundException;
import com.mybudget.backend.repository.TagRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TagService {

    private final TagRepository repo;

    public List<TagDto.Response> findAll() {
        User user = AuthContext.requireUser();
        return repo.findAllByUserIdOrderByNameAsc(user.getId()).stream()
                .map(TagDto.Response::from).toList();
    }

    @Transactional
    public TagDto.Response createOrGet(TagDto.CreateRequest req) {
        User user = AuthContext.requireUser();
        return repo.findByUserIdAndName(user.getId(), req.name())
                .map(TagDto.Response::from)
                .orElseGet(() -> TagDto.Response.from(
                        repo.save(Tag.builder().user(user).name(req.name()).color(req.color()).build())));
    }

    @Transactional
    public void delete(Long id) {
        User user = AuthContext.requireUser();
        Tag tag = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("Tag", id));
        repo.delete(tag);
    }
}
