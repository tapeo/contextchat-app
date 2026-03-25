import 'dart:convert';
import 'dart:typed_data';

import 'package:github/github.dart' hide CommitInfo;

import 'models/exceptions.dart';
import 'models/github_models.dart';
import 'models/sync_models.dart';

class SyncService {
  late final GitHub _github;
  RepositorySlug? _currentRepo;

  SyncService({String? token}) {
    _github = GitHub(
      auth: token != null
          ? Authentication.withToken(token)
          : const Authentication.anonymous(),
    );
  }

  void _setRepo(String owner, String repo) {
    _currentRepo = RepositorySlug(owner, repo);
  }

  Future<GitHubBranch> _getBranch(
    String owner,
    String repo,
    String branch, {
    required String token,
  }) async {
    _setRepo(owner, repo);
    _github.auth = Authentication.withToken(token);

    try {
      final ref = await _github.git.getReference(
        _currentRepo!,
        'heads/$branch',
      );
      final commit = await _github.git.getCommit(
        _currentRepo!,
        ref.object!.sha!,
      );

      return GitHubBranch(
        name: branch,
        commitSha: ref.object!.sha!,
        treeSha: commit.tree!.sha!,
        commitTimestamp: commit.committer?.date,
      );
    } on GitHubError catch (e) {
      if (e.toString().contains('404')) {
        throw BranchNotFoundException(branch);
      } else if (e.toString().contains('409')) {
        throw EmptyRepositoryException(
          'Repository is empty. Please create an initial commit first.',
        );
      }
      rethrow;
    }
  }

  Future<GitHubBranch> getOrCreateBranch(
    String owner,
    String repo,
    String branch, {
    required String token,
    String defaultBranch = 'main',
  }) async {
    _setRepo(owner, repo);
    _github.auth = Authentication.withToken(token);

    try {
      return await _getBranch(owner, repo, branch, token: token);
    } on BranchNotFoundException catch (_) {
      try {
        final defaultRef = await _github.git.getReference(
          _currentRepo!,
          'heads/$defaultBranch',
        );

        await _github.git.createReference(
          _currentRepo!,
          'refs/heads/$branch',
          defaultRef.object!.sha!,
        );

        final commit = await _github.git.getCommit(
          _currentRepo!,
          defaultRef.object!.sha!,
        );

        return GitHubBranch(
          name: branch,
          commitSha: defaultRef.object!.sha!,
          treeSha: commit.tree!.sha!,
          commitTimestamp: commit.committer?.date,
        );
      } on GitHubError catch (e) {
        if (e.toString().contains('409')) {
          return _createInitialCommitAndBranch(
            owner,
            repo,
            branch,
            token: token,
          );
        }

        if (defaultBranch == 'main') {
          try {
            final masterRef = await _github.git.getReference(
              _currentRepo!,
              'heads/master',
            );

            await _github.git.createReference(
              _currentRepo!,
              'refs/heads/$branch',
              masterRef.object!.sha!,
            );

            final commit = await _github.git.getCommit(
              _currentRepo!,
              masterRef.object!.sha!,
            );

            return GitHubBranch(
              name: branch,
              commitSha: masterRef.object!.sha!,
              treeSha: commit.tree!.sha!,
              commitTimestamp: commit.committer?.date,
            );
          } on GitHubError catch (e) {
            if (e.toString().contains('409')) {
              return _createInitialCommitAndBranch(
                owner,
                repo,
                branch,
                token: token,
              );
            }
            throw Exception('Could not find default branch (main or master)');
          }
        }
        throw Exception('Failed to create branch: $e');
      }
    } on EmptyRepositoryException catch (_) {
      return _createInitialCommitAndBranch(owner, repo, branch, token: token);
    }
  }

  Future<GitHubBranch> _createInitialCommitAndBranch(
    String owner,
    String repo,
    String branch, {
    required String token,
  }) async {
    _setRepo(owner, repo);
    _github.auth = Authentication.withToken(token);

    final readmeContent =
        '# ContextChat Sync Repository\n\n'
        'This repository is used for syncing ContextChat data.\n';

    final base64Content = base64Encode(utf8.encode(readmeContent));

    final result = await _github.repositories.createFile(
      _currentRepo!,
      CreateFile(
        path: 'README.md',
        message: 'Initial commit',
        content: base64Content,
        branch: branch,
      ),
    );

    final commitSha = result.commit!.sha!;
    final commit = await _github.git.getCommit(_currentRepo!, commitSha);

    return GitHubBranch(
      name: branch,
      commitSha: commitSha,
      treeSha: commit.tree!.sha!,
      commitTimestamp: commit.committer?.date,
    );
  }

  Future<GitHubTree> getTree(
    String owner,
    String repo,
    String treeSha, {
    required String token,
    bool recursive = true,
  }) async {
    _setRepo(owner, repo);
    _github.auth = Authentication.withToken(token);

    final tree = await _github.git.getTree(
      _currentRepo!,
      treeSha,
      recursive: recursive,
    );

    final entries =
        tree.entries
            ?.map(
              (e) => GitHubTreeEntry(
                path: e.path!,
                mode: e.mode!,
                type: e.type!,
                sha: e.sha,
                size: e.size,
              ),
            )
            .toList() ??
        [];

    return GitHubTree(sha: tree.sha!, entries: entries);
  }

  Future<GitHubBlob> getBlob(
    String owner,
    String repo,
    String blobSha, {
    required String token,
  }) async {
    _setRepo(owner, repo);
    _github.auth = Authentication.withToken(token);

    final blob = await _github.git.getBlob(_currentRepo!, blobSha);

    return GitHubBlob(
      sha: blob.sha!,
      content: blob.content ?? '',
      encoding: blob.encoding ?? 'utf-8',
      size: blob.size ?? 0,
    );
  }

  Future<String> createBlob(
    String owner,
    String repo,
    Uint8List content, {
    required String token,
  }) async {
    _setRepo(owner, repo);
    _github.auth = Authentication.withToken(token);

    final blob = await _github.git.createBlob(
      _currentRepo!,
      CreateGitBlob(base64Encode(content), 'base64'),
    );

    return blob.sha!;
  }

  Future<String> createTree(
    String owner,
    String repo,
    String baseTreeSha,
    List<Map<String, dynamic>> entries, {
    required String token,
  }) async {
    _setRepo(owner, repo);
    _github.auth = Authentication.withToken(token);

    final treeEntries = entries
        .map(
          (e) => CreateGitTreeEntry(
            e['path'] as String,
            e['mode'] as String,
            e['type'] as String,
            sha: e.containsKey('sha') ? e['sha'] as String? : null,
          ),
        )
        .toList();

    final tree = await _github.git.createTree(
      _currentRepo!,
      CreateGitTree(treeEntries, baseTree: baseTreeSha),
    );

    return tree.sha!;
  }

  Future<String> createCommit(
    String owner,
    String repo,
    String message,
    String treeSha,
    List<String> parentShas, {
    required String token,
  }) async {
    _setRepo(owner, repo);
    _github.auth = Authentication.withToken(token);

    final commit = await _github.git.createCommit(
      _currentRepo!,
      CreateGitCommit(message, treeSha, parents: parentShas),
    );

    return commit.sha!;
  }

  Future<void> updateRef(
    String owner,
    String repo,
    String ref,
    String commitSha, {
    required String token,
  }) async {
    _setRepo(owner, repo);
    _github.auth = Authentication.withToken(token);

    await _github.git.editReference(
      _currentRepo!,
      ref,
      commitSha,
      force: false,
    );
  }

  Future<CompareResult> compareCommits(
    String owner,
    String repo,
    String base,
    String head, {
    required String token,
  }) async {
    _setRepo(owner, repo);
    _github.auth = Authentication.withToken(token);

    final comparison = await _github.repositories.compareCommits(
      _currentRepo!,
      base,
      head,
    );

    final commits =
        comparison.commits
            ?.map(
              (c) => CommitInfo(
                sha: c.sha!,
                message: c.commit?.message ?? '',
                date: c.commit?.committer?.date,
                author: c.commit?.author?.name,
              ),
            )
            .toList() ??
        [];

    final files =
        comparison.files
            ?.map(
              (f) => FileChange(
                path: f.name ?? '',
                status: f.status ?? '',
                additions: f.additions,
                deletions: f.deletions,
                changes: f.changes,
              ),
            )
            .toList() ??
        [];

    return CompareResult(
      status: comparison.status ?? 'unknown',
      aheadBy: comparison.aheadBy ?? 0,
      behindBy: comparison.behindBy ?? 0,
      totalCommits: comparison.totalCommits ?? 0,
      commits: commits,
      files: files,
    );
  }

  Future<DateTime?> getCommitTimestamp(
    String owner,
    String repo,
    String commitSha, {
    required String token,
  }) async {
    _setRepo(owner, repo);
    _github.auth = Authentication.withToken(token);

    try {
      final commit = await _github.git.getCommit(_currentRepo!, commitSha);
      return commit.committer?.date;
    } catch (_) {
      return null;
    }
  }
}
