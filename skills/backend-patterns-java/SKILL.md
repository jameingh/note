# 后端开发模式（Java / Spring Boot 3.1.1 / MyBatis-Plus）

适用于可扩展 Java 服务端应用程序的后端架构模式与最佳实践。

**技术栈：** Java 17+ · Spring Boot 3.1.1 · Maven · MyBatis-Plus 3.5.x · Spring Security · Redis · Lombok · SLF4J / Logback

---

## 激活时机

- 设计 REST API 端点（Controller / Service / Mapper 三层架构）时
- 实现 Repository（Mapper）、Service、Controller 层时
- 优化数据库查询（N+1、索引、连接池）时
- 添加缓存（Redis、Spring Cache、HTTP Cache）时
- 设置后台异步任务（`@Async`、`@Scheduled`、Spring Events）时
- 为 API 构建统一异常处理与参数校验时
- 构建中间件（拦截器、过滤器、认证、日志、限流）时

---

## pom.xml 核心依赖

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.1.1</version>
</parent>

<dependencies>
    <!-- Web -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <!-- MyBatis-Plus -->
    <dependency>
        <groupId>com.baomidou</groupId>
        <artifactId>mybatis-plus-boot-starter</artifactId>
        <version>3.5.3.2</version>
    </dependency>

    <!-- 数据库驱动（MySQL 示例） -->
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <scope>runtime</scope>
    </dependency>

    <!-- Redis -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
    </dependency>

    <!-- Spring Security -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>

    <!-- JWT -->
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-api</artifactId>
        <version>0.11.5</version>
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-impl</artifactId>
        <version>0.11.5</version>
        <scope>runtime</scope>
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-jackson</artifactId>
        <version>0.11.5</version>
        <scope>runtime</scope>
    </dependency>

    <!-- 参数校验 -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>

    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
</dependencies>
```

---

## API 设计模式

### RESTful API 结构

```java
// ✅ 通过：基于资源的 URL + 标准 HTTP 方法
@RestController
@RequestMapping("/api/markets")
@RequiredArgsConstructor
public class MarketController {

    private final MarketService marketService;

    // GET /api/markets?status=active&sort=volume&pageNum=1&pageSize=20
    @GetMapping
    public R<IPage<MarketVO>> list(@Valid MarketQueryDTO query) {
        return R.ok(marketService.page(query));
    }

    // GET /api/markets/{id}
    @GetMapping("/{id}")
    public R<MarketVO> getById(@PathVariable Long id) {
        return R.ok(marketService.getById(id));
    }

    // POST /api/markets
    @PostMapping
    public R<MarketVO> create(@RequestBody @Valid CreateMarketDTO dto) {
        return R.ok(marketService.create(dto));
    }

    // PUT /api/markets/{id}
    @PutMapping("/{id}")
    public R<MarketVO> update(@PathVariable Long id,
                               @RequestBody @Valid UpdateMarketDTO dto) {
        return R.ok(marketService.update(id, dto));
    }

    // DELETE /api/markets/{id}
    @DeleteMapping("/{id}")
    public R<Void> delete(@PathVariable Long id) {
        marketService.delete(id);
        return R.ok();
    }
}
```

### 统一响应包装

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class R<T> {
    private int code;
    private String message;
    private T data;

    public static <T> R<T> ok() {
        return new R<>(200, "success", null);
    }

    public static <T> R<T> ok(T data) {
        return new R<>(200, "success", data);
    }

    public static <T> R<T> fail(int code, String message) {
        return new R<>(code, message, null);
    }
}
```

---

## 仓库层模式（Mapper）

### MyBatis-Plus 基础 Mapper

```java
// ✅ 继承 BaseMapper，即可获得 CRUD 能力，无需写 XML
@Mapper
public interface MarketMapper extends BaseMapper<Market> {

    // 自定义复杂查询：使用注解
    @Select("SELECT * FROM market WHERE status = #{status} ORDER BY volume DESC LIMIT #{limit}")
    List<Market> findTopByStatus(@Param("status") String status,
                                  @Param("limit") int limit);
}
```

### 使用 QueryWrapper 构建条件查询

```java
// ✅ 通过：链式条件构建，避免 SQL 拼接
@Service
@RequiredArgsConstructor
public class MarketRepositoryImpl {

    private final MarketMapper marketMapper;

    public IPage<Market> findAll(MarketQueryDTO query) {
        LambdaQueryWrapper<Market> wrapper = Wrappers.<Market>lambdaQuery()
            .eq(StringUtils.hasText(query.getStatus()),
                Market::getStatus, query.getStatus())
            .ge(query.getMinVolume() != null,
                Market::getVolume, query.getMinVolume())
            .orderByDesc(Market::getVolume);

        Page<Market> page = new Page<>(query.getPageNum(), query.getPageSize());
        return marketMapper.selectPage(page, wrapper);
    }

    public Optional<Market> findById(Long id) {
        return Optional.ofNullable(marketMapper.selectById(id));
    }
}
```

### MyBatis-Plus 实体配置

```java
@Data
@TableName("market")
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Market {

    @TableId(type = IdType.ASSIGN_ID)   // 雪花 ID
    private Long id;

    private String name;
    private String status;
    private BigDecimal volume;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;

    @TableLogic                          // 逻辑删除
    private Integer deleted;
}
```

---

## 服务层模式

```java
// ✅ 业务逻辑与数据访问分离；IService 提供分页、批量等方法
@Service
@RequiredArgsConstructor
public class MarketServiceImpl extends ServiceImpl<MarketMapper, Market>
        implements MarketService {

    private final MarketMapper marketMapper;
    private final UserMapper   userMapper;

    @Override
    public IPage<MarketVO> page(MarketQueryDTO query) {
        IPage<Market> page = new Page<>(query.getPageNum(), query.getPageSize());

        LambdaQueryWrapper<Market> wrapper = Wrappers.<Market>lambdaQuery()
            .eq(StringUtils.hasText(query.getStatus()),
                Market::getStatus, query.getStatus())
            .orderByDesc(Market::getVolume);

        IPage<Market> result = marketMapper.selectPage(page, wrapper);
        return result.convert(this::toVO);
    }

    @Override
    public MarketVO getById(Long id) {
        Market market = marketMapper.selectById(id);
        if (market == null) {
            throw new BizException(ErrorCode.MARKET_NOT_FOUND);
        }
        return toVO(market);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public MarketVO create(CreateMarketDTO dto) {
        Market market = Market.builder()
            .name(dto.getName())
            .status("ACTIVE")
            .volume(BigDecimal.ZERO)
            .build();
        marketMapper.insert(market);
        return toVO(market);
    }

    private MarketVO toVO(Market market) {
        // 对象转换，推荐使用 MapStruct
        MarketVO vo = new MarketVO();
        BeanUtils.copyProperties(market, vo);
        return vo;
    }
}
```

---

## 中间件模式

### 认证拦截器（HandlerInterceptor）

```java
// ✅ 请求/响应处理管道
@Component
@RequiredArgsConstructor
public class AuthInterceptor implements HandlerInterceptor {

    private final JwtUtil jwtUtil;

    @Override
    public boolean preHandle(HttpServletRequest request,
                              HttpServletResponse response,
                              Object handler) throws Exception {

        String token = request.getHeader("Authorization");
        if (token != null && token.startsWith("Bearer ")) {
            token = token.substring(7);
        } else {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            writeJson(response, R.fail(401, "未经授权"));
            return false;
        }

        try {
            UserClaims claims = jwtUtil.parseToken(token);
            // 存入 ThreadLocal，供 Controller 使用
            UserContext.set(claims);
            return true;
        } catch (JwtException e) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            writeJson(response, R.fail(401, "无效令牌"));
            return false;
        }
    }

    @Override
    public void afterCompletion(HttpServletRequest request,
                                 HttpServletResponse response,
                                 Object handler, Exception ex) {
        UserContext.clear();   // 防止内存泄漏
    }

    private void writeJson(HttpServletResponse response, Object body) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write(new ObjectMapper().writeValueAsString(body));
    }
}

// 注册拦截器
@Configuration
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {

    private final AuthInterceptor authInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(authInterceptor)
            .addPathPatterns("/api/**")
            .excludePathPatterns("/api/auth/**");
    }
}
```

### 请求日志过滤器

```java
@Component
@Slf4j
public class RequestLoggingFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                     HttpServletResponse response,
                                     FilterChain chain)
            throws ServletException, IOException {

        String requestId = UUID.randomUUID().toString();
        long start = System.currentTimeMillis();

        MDC.put("requestId", requestId);
        try {
            chain.doFilter(request, response);
        } finally {
            long cost = System.currentTimeMillis() - start;
            log.info("method={} uri={} status={} cost={}ms requestId={}",
                request.getMethod(), request.getRequestURI(),
                response.getStatus(), cost, requestId);
            MDC.clear();
        }
    }
}
```

---

## 数据库模式

### 查询优化

```java
// ✅ 通过：仅查询需要的列，使用 select() 限制字段
List<MarketVO> list = marketMapper.selectList(
    Wrappers.<Market>lambdaQuery()
        .select(Market::getId, Market::getName,
                Market::getStatus, Market::getVolume)
        .eq(Market::getStatus, "active")
        .orderByDesc(Market::getVolume)
        .last("LIMIT 10")
);

// ❌ 未通过：不良实践 - 查询所有列
List<Market> list = marketMapper.selectList(null);
```

### N+1 查询预防

```java
// ❌ 未通过：N+1 查询问题
List<Market> markets = marketMapper.selectList(null);
for (Market market : markets) {
    User creator = userMapper.selectById(market.getCreatorId());  // N 次查询
    market.setCreator(creator);
}

// ✅ 通过：批量 IN 查询，降为 1 次
List<Market> markets = marketMapper.selectList(null);

List<Long> creatorIds = markets.stream()
    .map(Market::getCreatorId)
    .distinct()
    .collect(Collectors.toList());

// MyBatis-Plus 的 selectBatchIds
List<User> creators = userMapper.selectBatchIds(creatorIds);
Map<Long, User> creatorMap = creators.stream()
    .collect(Collectors.toMap(User::getId, u -> u));

markets.forEach(m -> m.setCreator(creatorMap.get(m.getCreatorId())));
```

### 分页查询

```java
// ✅ 通过：MyBatis-Plus 分页插件（需在配置中注册 MybatisPlusInterceptor）
@Bean
public MybatisPlusInterceptor mybatisPlusInterceptor() {
    MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
    interceptor.addInnerInterceptor(new PaginationInnerInterceptor(DbType.MYSQL));
    return interceptor;
}

// Service 中使用
IPage<Market> page = marketMapper.selectPage(
    new Page<>(pageNum, pageSize),
    Wrappers.<Market>lambdaQuery().eq(Market::getStatus, "active")
);
```

### 事务模式

```java
// ✅ Spring 声明式事务
@Transactional(rollbackFor = Exception.class)
public MarketVO createMarketWithPosition(CreateMarketDTO marketDto,
                                          CreatePositionDTO positionDto) {
    // 两次插入在同一事务中
    Market market = buildMarket(marketDto);
    marketMapper.insert(market);

    Position position = buildPosition(positionDto, market.getId());
    positionMapper.insert(position);

    return toVO(market);
    // 任一步骤抛出异常，自动回滚
}
```

---

## 缓存策略

### Redis 缓存层

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class CachedMarketService {

    private final MarketMapper    marketMapper;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper    objectMapper;

    private static final String CACHE_PREFIX = "market:";
    private static final long   CACHE_TTL    = 300L;  // 5 分钟

    public MarketVO findById(Long id) throws JsonProcessingException {
        String cacheKey = CACHE_PREFIX + id;

        // 先检查缓存
        String cached = redisTemplate.opsForValue().get(cacheKey);
        if (cached != null) {
            return objectMapper.readValue(cached, MarketVO.class);
        }

        // 缓存未命中 - 从数据库获取
        Market market = marketMapper.selectById(id);
        if (market == null) {
            throw new BizException(ErrorCode.MARKET_NOT_FOUND);
        }

        MarketVO vo = toVO(market);
        // 写入缓存，设置 TTL
        redisTemplate.opsForValue().set(
            cacheKey,
            objectMapper.writeValueAsString(vo),
            Duration.ofSeconds(CACHE_TTL)
        );
        return vo;
    }

    public void invalidateCache(Long id) {
        redisTemplate.delete(CACHE_PREFIX + id);
    }
}
```

### Spring Cache 注解方式

```java
// ✅ 更简洁：使用 @Cacheable / @CacheEvict
@Service
@CacheConfig(cacheNames = "market")
public class MarketServiceImpl {

    @Cacheable(key = "#id", unless = "#result == null")
    public MarketVO getById(Long id) {
        Market market = marketMapper.selectById(id);
        return toVO(market);
    }

    @CacheEvict(key = "#id")
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        marketMapper.deleteById(id);
    }

    @CachePut(key = "#result.id")
    @Transactional(rollbackFor = Exception.class)
    public MarketVO update(Long id, UpdateMarketDTO dto) {
        // 更新数据库并刷新缓存
        Market market = marketMapper.selectById(id);
        BeanUtils.copyProperties(dto, market);
        marketMapper.updateById(market);
        return toVO(market);
    }
}
```

---

## 错误处理模式

### 业务异常类

```java
@Getter
public class BizException extends RuntimeException {

    private final int    code;
    private final String message;

    public BizException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.code    = errorCode.getCode();
        this.message = errorCode.getMessage();
    }

    public BizException(int code, String message) {
        super(message);
        this.code    = code;
        this.message = message;
    }
}

@Getter
@AllArgsConstructor
public enum ErrorCode {
    MARKET_NOT_FOUND(404, "市场不存在"),
    UNAUTHORIZED(401, "未经授权"),
    FORBIDDEN(403, "权限不足"),
    INVALID_PARAM(400, "参数错误"),
    INTERNAL_ERROR(500, "服务器内部错误");

    private final int    code;
    private final String message;
}
```

### 全局异常处理器

```java
// ✅ 集中式错误处理，等价于 Next.js 的 errorHandler
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    // 业务异常
    @ExceptionHandler(BizException.class)
    public R<Void> handleBizException(BizException e) {
        return R.fail(e.getCode(), e.getMessage());
    }

    // 参数校验失败（@Valid）
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public R<Map<String, String>> handleValidationException(
            MethodArgumentNotValidException e) {

        Map<String, String> errors = new LinkedHashMap<>();
        e.getBindingResult().getFieldErrors()
            .forEach(fe -> errors.put(fe.getField(), fe.getDefaultMessage()));

        return new R<>(400, "参数校验失败", errors);
    }

    // 参数类型错误
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public R<Void> handleTypeMismatch(MethodArgumentTypeMismatchException e) {
        return R.fail(400, "参数类型错误: " + e.getName());
    }

    // 兜底处理
    @ExceptionHandler(Exception.class)
    public R<Void> handleException(Exception e) {
        log.error("未知异常", e);
        return R.fail(500, "服务器内部错误");
    }
}
```

### 指数退避重试

```java
// ✅ 使用 Spring Retry 实现指数退避
// 1. 添加依赖：spring-retry + aspectjweaver
// 2. 启动类加 @EnableRetry

@Service
public class ExternalApiService {

    @Retryable(
        value  = { IOException.class, HttpClientErrorException.class },
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2)  // 1s, 2s, 4s
    )
    public String fetchFromApi(String url) {
        // 调用外部 API
        return restTemplate.getForObject(url, String.class);
    }

    @Recover
    public String recover(Exception e, String url) {
        log.error("重试均失败，url={}", url, e);
        throw new BizException(ErrorCode.INTERNAL_ERROR);
    }
}
```

---

## 认证与授权

### JWT 工具类

```java
@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration:86400}")
    private long expiration;  // 秒

    public String generateToken(UserClaims claims) {
        return Jwts.builder()
            .setSubject(claims.getUserId().toString())
            .claim("email", claims.getEmail())
            .claim("role",  claims.getRole())
            .setIssuedAt(new Date())
            .setExpiration(new Date(System.currentTimeMillis() + expiration * 1000))
            .signWith(getKey(), SignatureAlgorithm.HS256)
            .compact();
    }

    public UserClaims parseToken(String token) {
        Claims claims = Jwts.parserBuilder()
            .setSigningKey(getKey())
            .build()
            .parseClaimsJws(token)
            .getBody();

        return UserClaims.builder()
            .userId(Long.parseLong(claims.getSubject()))
            .email(claims.get("email", String.class))
            .role(claims.get("role",  String.class))
            .build();
    }

    private Key getKey() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }
}

@Data
@Builder
public class UserClaims {
    private Long   userId;
    private String email;
    private String role;   // "admin" | "moderator" | "user"
}
```

### UserContext（ThreadLocal 存储）

```java
public class UserContext {

    private static final ThreadLocal<UserClaims> holder = new ThreadLocal<>();

    public static void set(UserClaims claims) { holder.set(claims); }

    public static UserClaims get() {
        UserClaims claims = holder.get();
        if (claims == null) {
            throw new BizException(ErrorCode.UNAUTHORIZED);
        }
        return claims;
    }

    public static void clear() { holder.remove(); }
}
```

### 基于角色的访问控制（RBAC）

```java
// 1. 自定义权限注解
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface RequirePermission {
    String[] value();  // e.g. "read", "write", "delete", "admin"
}

// 2. AOP 切面
@Aspect
@Component
@RequiredArgsConstructor
@Slf4j
public class PermissionAspect {

    private static final Map<String, List<String>> ROLE_PERMISSIONS = Map.of(
        "admin",     List.of("read", "write", "delete", "admin"),
        "moderator", List.of("read", "write", "delete"),
        "user",      List.of("read", "write")
    );

    @Around("@annotation(requirePermission)")
    public Object checkPermission(ProceedingJoinPoint pjp,
                                   RequirePermission requirePermission) throws Throwable {
        UserClaims user = UserContext.get();
        List<String> permissions = ROLE_PERMISSIONS
            .getOrDefault(user.getRole(), Collections.emptyList());

        for (String perm : requirePermission.value()) {
            if (!permissions.contains(perm)) {
                throw new BizException(ErrorCode.FORBIDDEN);
            }
        }
        return pjp.proceed();
    }
}

// 3. 在 Service 或 Controller 上使用
@DeleteMapping("/{id}")
@RequirePermission("delete")
public R<Void> delete(@PathVariable Long id) {
    marketService.delete(id);
    return R.ok();
}
```

---

## 速率限制

### 基于 Redis 的滑动窗口限流

```java
@Component
@RequiredArgsConstructor
@Slf4j
public class RateLimiter {

    private final StringRedisTemplate redisTemplate;

    /**
     * @param identifier  限流 key（如 IP 或 userId）
     * @param maxRequests 窗口内最大请求数
     * @param windowMs    窗口大小（毫秒）
     * @return true = 允许通过；false = 超出限制
     */
    public boolean isAllowed(String identifier, int maxRequests, long windowMs) {
        String key = "rate_limit:" + identifier;
        long now = System.currentTimeMillis();
        long windowStart = now - windowMs;

        // 使用 Redis ZSet 实现滑动窗口
        redisTemplate.opsForZSet().removeRangeByScore(key, 0, windowStart);
        Long count = redisTemplate.opsForZSet().zCard(key);

        if (count != null && count >= maxRequests) {
            return false;
        }

        redisTemplate.opsForZSet().add(key, String.valueOf(now), now);
        redisTemplate.expire(key, Duration.ofMillis(windowMs));
        return true;
    }
}

// 限流拦截器
@Component
@RequiredArgsConstructor
public class RateLimitInterceptor implements HandlerInterceptor {

    private final RateLimiter rateLimiter;

    @Override
    public boolean preHandle(HttpServletRequest request,
                              HttpServletResponse response,
                              Object handler) throws Exception {

        String ip = getClientIp(request);
        if (!rateLimiter.isAllowed(ip, 100, 60_000L)) {  // 100次/分钟
            response.setStatus(429);
            writeJson(response, R.fail(429, "请求过于频繁"));
            return false;
        }
        return true;
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        return (ip == null || ip.isBlank()) ? request.getRemoteAddr() : ip.split(",")[0].trim();
    }

    // 复用 AuthInterceptor 的 writeJson
}
```

---

## 后台任务与异步处理

### 异步方法（@Async）

```java
// 1. 启动类加 @EnableAsync
// 2. 配置线程池
@Configuration
public class AsyncConfig {

    @Bean("taskExecutor")
    public ThreadPoolTaskExecutor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5);
        executor.setMaxPoolSize(20);
        executor.setQueueCapacity(500);
        executor.setThreadNamePrefix("async-task-");
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        executor.initialize();
        return executor;
    }
}

// 3. 异步 Service
@Service
@Slf4j
public class IndexService {

    @Async("taskExecutor")
    public CompletableFuture<Void> indexMarket(Long marketId) {
        try {
            // 耗时的索引逻辑
            log.info("正在索引市场 id={}", marketId);
            doIndex(marketId);
            return CompletableFuture.completedFuture(null);
        } catch (Exception e) {
            log.error("索引市场失败 id={}", marketId, e);
            return CompletableFuture.failedFuture(e);
        }
    }
}

// 4. Controller 中使用（不阻塞主线程）
@PostMapping("/{id}/index")
public R<String> triggerIndex(@PathVariable Long id) {
    indexService.indexMarket(id);          // 异步，立即返回
    return R.ok("索引任务已提交");
}
```

### 定时任务（@Scheduled）

```java
@Component
@Slf4j
@RequiredArgsConstructor
public class MarketScheduler {

    private final MarketService marketService;

    // 每 5 分钟刷新市场数据
    @Scheduled(fixedDelay = 5 * 60 * 1000)
    public void refreshMarkets() {
        log.info("开始刷新市场数据...");
        marketService.refresh();
    }

    // 每天凌晨 2 点执行清理
    @Scheduled(cron = "0 0 2 * * ?")
    public void cleanExpiredData() {
        log.info("开始清理过期数据...");
        marketService.cleanExpired();
    }
}
```

### Spring Events（发布/订阅）

```java
// 事件类
@Getter
@AllArgsConstructor
public class MarketCreatedEvent {
    private final Market market;
}

// 发布
@Service
@RequiredArgsConstructor
public class MarketServiceImpl {

    private final ApplicationEventPublisher eventPublisher;

    @Transactional(rollbackFor = Exception.class)
    public MarketVO create(CreateMarketDTO dto) {
        Market market = insertMarket(dto);
        eventPublisher.publishEvent(new MarketCreatedEvent(market));  // 解耦
        return toVO(market);
    }
}

// 监听（异步）
@Component
@Slf4j
public class MarketEventListener {

    @Async
    @EventListener
    public void onMarketCreated(MarketCreatedEvent event) {
        log.info("收到市场创建事件 id={}", event.getMarket().getId());
        // 发通知、写审计日志等
    }
}
```

---

## 日志记录与监控

### 结构化日志（SLF4J + Logback + MDC）

```java
// ✅ 使用 @Slf4j + MDC 实现结构化日志，等价于 TypeScript Logger 类
@RestController
@RequestMapping("/api/markets")
@RequiredArgsConstructor
@Slf4j
public class MarketController {

    private final MarketService marketService;

    @GetMapping
    public R<IPage<MarketVO>> list(@Valid MarketQueryDTO query) {
        // MDC 中的 requestId 由 RequestLoggingFilter 注入
        log.info("获取市场列表 status={} pageNum={}", query.getStatus(), query.getPageNum());

        try {
            IPage<MarketVO> result = marketService.page(query);
            log.info("获取市场列表成功 total={}", result.getTotal());
            return R.ok(result);
        } catch (BizException e) {
            log.warn("获取市场列表业务异常 code={} msg={}", e.getCode(), e.getMessage());
            throw e;
        } catch (Exception e) {
            log.error("获取市场列表未知异常", e);
            throw new BizException(ErrorCode.INTERNAL_ERROR);
        }
    }
}
```

### logback-spring.xml 配置（JSON 输出）

```xml
<configuration>
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
            <providers>
                <timestamp/>
                <logLevel/>
                <loggerName/>
                <message/>
                <mdc/>              <!-- 输出 requestId 等 MDC 字段 -->
                <stackTrace/>
            </providers>
        </encoder>
    </appender>

    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
    </root>
</configuration>
```

---

## 参数校验

```java
// ✅ 使用 Bean Validation（等价于 Zod 校验）
@Data
public class CreateMarketDTO {

    @NotBlank(message = "市场名称不能为空")
    @Size(min = 2, max = 100, message = "名称长度 2-100 字符")
    private String name;

    @NotNull(message = "类型不能为空")
    @Pattern(regexp = "STOCK|CRYPTO|FOREX", message = "类型只能是 STOCK/CRYPTO/FOREX")
    private String type;

    @DecimalMin(value = "0.01", message = "最小交易量不能小于 0.01")
    private BigDecimal minVolume;
}

// Controller 加 @Valid，参数错误由 GlobalExceptionHandler 统一处理
@PostMapping
public R<MarketVO> create(@RequestBody @Valid CreateMarketDTO dto) {
    return R.ok(marketService.create(dto));
}
```

---

## 最佳实践总结

| 层次 | 原则 |
|------|------|
| **Controller** | 只做参数接收与响应封装，不含业务逻辑 |
| **Service** | 业务逻辑集中，事务在 Service 层管理 |
| **Mapper** | 数据访问，复杂 SQL 用 XML，简单用 QueryWrapper |
| **DTO/VO** | 入参用 DTO（含校验注解），出参用 VO，实体不外泄 |
| **异常** | 统一 `BizException` + `GlobalExceptionHandler`，禁止吞异常 |
| **事务** | 只加在 Service 层，`rollbackFor = Exception.class` |
| **缓存** | 优先 `@Cacheable` 注解，失效策略一定要有 |
| **日志** | 使用 `@Slf4j` + `MDC`，结构化日志，错误附完整堆栈 |
| **安全** | 密钥走 `@Value` 注入，不硬编码；JWT 密钥建议 256 位以上 |

---

**记住**：三层架构（Controller → Service → Mapper）是 Spring Boot 项目的骨架。
选择适合当前复杂度的模式，不要过度设计。
