# Shared Fixtures

共用測試資料定義，可被多個測試套件引用。

## 結構

```
shared/
├── fixtures/           # 資料定義 YAML
│   ├── users.yml       # 共用使用者
│   └── base_data.yml   # 基礎資料
└── helpers/            # 共用 helpers
    └── login_helper.rb # 登入輔助
```

## 使用方式

### 1. 在 suite.yml 中宣告依賴

```yaml
dependencies:
  shared:
    - "users.yml"
    - "base_data.yml"
```

### 2. 在 seed 腳本中載入

```ruby
def load_shared_fixtures
  fixtures_path = File.expand_path('../../shared/fixtures', __dir__)

  users = YAML.load_file(File.join(fixtures_path, 'users.yml'))
  create_user_from_fixture(users['accountant'])
end
```

## 命名規範

- **YAML 檔案**：使用 snake_case，如 `base_data.yml`
- **使用者 key**：使用有意義的角色名稱，如 `admin`、`accountant`
- **資料 key**：使用描述性名稱，如 `valid_invoice`、`pending_period`

## 注意事項

1. **不要包含敏感資料**：密碼、API key 等應由測試環境提供
2. **使用測試 email domain**：如 `@test.example.com`
3. **提供 notes 說明**：每個 fixture 都應說明用途
