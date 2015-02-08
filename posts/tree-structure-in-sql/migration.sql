CREATE DATABASE test_sql_tree CHARACTER SET utf8 COLLATE utf8_general_ci;
USE test_sql_tree;

-- Adjacency List --------------------------------------------------------------

DROP TABLE IF EXISTS comment_tree_paths;
DROP TABLE IF EXISTS comments;

CREATE TABLE comments (
  comment_id	BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  parent_id		BIGINT UNSIGNED,							-- 新欄位
  bug_id		BIGINT UNSIGNED NOT NULL,
  author		TEXT NOT NULL,
  comment_text	TEXT NOT NULL,

  FOREIGN KEY (parent_id) REFERENCES comments(comment_id) ON DELETE CASCADE
);

INSERT INTO comments (parent_id, bug_id, author, comment_text) VALUES
  (NULL, 1234, 'Fran', '為什麼會有這個 bug ?'),
  (1, 1234, 'Ollie', '我想應該是 null pointer。'),
  (2, 1234, 'Fran', '不是，我確認過了。'),
  (1, 1234, 'Kukla', '應該要去檢查錯誤資料。'),
  (4, 1234, 'Ollie', '對，這是個 bug。'),
  (4, 1234, 'Fran', '請加上個檢查。'),
  (6, 1234, 'Kukla', '加上去後就好了。');


-- Path Enumeration ------------------------------------------------------------

DROP TABLE IF EXISTS comment_tree_paths;
DROP TABLE IF EXISTS comments;

CREATE TABLE comments (
  comment_id	BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  path			VARCHAR(1000),								-- 新欄位
  bug_id		BIGINT UNSIGNED NOT NULL,
  author		TEXT NOT NULL,
  comment_text	TEXT NOT NULL
);

INSERT INTO comments (path, bug_id, author, comment_text) VALUES
  ('1/', 1234, 'Fran', '為什麼會有這個 bug ?'),
  ('1/2/', 1234, 'Ollie', '我想應該是 null pointer。'),
  ('1/2/3/', 1234, 'Fran', '不是，我確認過了。'),
  ('1/4/', 1234, 'Kukla', '應該要去檢查錯誤資料。'),
  ('1/4/5/', 1234, 'Ollie', '對，這是個 bug。'),
  ('1/4/6/', 1234, 'Fran', '請加上個檢查。'),
  ('1/4/6/7/', 1234, 'Kukla', '加上去後就好了。');

-- Nested Sets -----------------------------------------------------------------

DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS comment_tree_paths;

CREATE TABLE comments (
  comment_id	BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nsleft		INTEGER NOT NULL,							-- 新欄位
  nsright		INTEGER NOT NULL,							-- 新欄位
  bug_id		BIGINT UNSIGNED NOT NULL,
  author		TEXT NOT NULL,
  comment_text	TEXT NOT NULL
);

INSERT INTO comments (nsleft, nsright, bug_id, author, comment_text) VALUES
  (1, 14, 1234, 'Fran', '為什麼會有這個 bug ?'),
  (2, 5, 1234, 'Ollie', '我想應該是 null pointer。'),
  (3, 4, 1234, 'Fran', '不是，我確認過了。'),
  (6, 13, 1234, 'Kukla', '應該要去檢查錯誤資料。'),
  (7, 8, 1234, 'Ollie', '對，這是個 bug。'),
  (9, 12, 1234, 'Fran', '請加上個檢查。'),
  (10, 11, 1234, 'Kukla', '加上去後就好了。');

-- Closure Table ---------------------------------------------------------------

DROP TABLE IF EXISTS comment_tree_paths;
DROP TABLE IF EXISTS comments;

CREATE TABLE comments (
  comment_id	BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  bug_id		BIGINT UNSIGNED NOT NULL,
  author		TEXT NOT NULL,
  comment_text	TEXT NOT NULL
);

CREATE TABLE comment_tree_paths (
  ancestor		BIGINT UNSIGNED NOT NULL,
  descendant 	BIGINT UNSIGNED NOT NULL,

  PRIMARY KEY(ancestor, descendant),
  FOREIGN KEY (ancestor) REFERENCES comments(comment_id) ON DELETE CASCADE,
  FOREIGN KEY (descendant) REFERENCES comments(comment_id) ON DELETE CASCADE
);

INSERT INTO comments (bug_id, author, comment_text) VALUES
  (1234, 'Fran', '為什麼會有這個 bug ?'),
  (1234, 'Ollie', '我想應該是 null pointer。'),
  (1234, 'Fran', '不是，我確認過了。'),
  (1234, 'Kukla', '應該要去檢查錯誤資料。'),
  (1234, 'Ollie', '對，這是個 bug。'),
  (1234, 'Fran', '請加上個檢查。'),
  (1234, 'Kukla', '加上去後就好了。');

INSERT INTO comment_tree_paths VALUES
  (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
  (2, 2), (2, 3),
  (3, 3),
  (4, 4), (4, 5), (4, 6), (4, 7),
  (5, 5),
  (6, 6), (6, 7),
  (7, 7);
