<!-- Copyright (c) Vaidya Solutions -->
<!-- SPDX-License-Identifier: BSD-3-Clause -->
<!-- -->
<!-- docs/shared/prompts/research/deep-research-template.md -->
<!-- @file docs/shared/prompts/research/deep-research-template.md -->
<!-- @description General-purpose template for conducting deep research and analysis tasks. -->
<!-- @update-policy Update when the core research workflow or architectural guideline summary materially changes. -->

# 🧠 GENERAL-PURPOSE DEEP RESEARCH PROMPT TEMPLATE

## 🔍 CRITICAL RESEARCH INSTRUCTION

This is a **research and analysis task.** Your primary function is to gather, validate, and synthesize authoritative information to form a comprehensive plan or report. **Execution (like writing code or creating infrastructure) is a separate step that will come after this research is complete.** You may, however, provide small illustrative examples.

Your analysis should be grounded in trusted documentation, whitepapers, architectural blogs, and vendor guidance.

**AI CONTEXT AWARENESS:**
- **ChatGPT / Claude:** You likely have access to the codebase. Use it to verify assumptions.
- **Gemini:** You may **NOT** have access to the codebase. Rely on the context provided in this prompt and your internal knowledge base. Do not hallucinate file paths or existing implementations.

---

### 1. Primary Objective
*This section is for you to define the high-level goal.*

**Example:**
> "Analyze our current monolith application and produce a detailed, phased migration plan to a microservices architecture on AWS, focusing on improving scalability and developer velocity."

**YOUR OBJECTIVE:**
> `[Clearly state the primary goal of this research task. What question are you trying to answer or what problem are you trying to solve?]`

---

### 2. Context & Scope
*Provide the necessary background for the AI to understand the domain. The more relevant details, the better the output.*

* **Current Situation:**
    > `[Describe the existing system, architecture, codebase, or process. Include relevant technologies, team structures, and current pain points.]`

* **Desired Future State / Goals:**
    > `[Describe the target outcome. What does success look like? What are the key features or characteristics of the desired state?]`

* **Project Structure & Tech Stack:**
    > * **Frontend:** TypeScript/React in `@services/gideon-frontend/` (Vite, Bun, shadcn/ui).
    > * **Platform:** AWS Agent Core (Managed Runtime).
    > * **Backend Core:** Go (Golang) in `@internal/` (business logic, MCP server).
    > * **Infrastructure:** Terraform in `@infra/terraform/` and AWS Lambdas.
    > * **Quality Gates:** Robust checks in `@cmd/devtools/gatekeeper/` (must pass for commits).
    > * **Tooling:** Development environment via `@cmd/devenv/` and utilities in `@cmd/devtools/`.

* **In-Scope Files:**
    > `[Specify which parts of the codebase are relevant. For example: "The entire services/gideon-frontend directory," or "Focus on the components within internal/transport/."]`

* **Architectural Guidelines (CRITICAL):**
    > **Rule Source:**
    > * **Cursor:** Follow `@.cursor/rules` (Automated).
    > * **VS Code/Copilot:** Follow `@.github/instructions` (Functional parity with Cursor rules).
    >
    > **Core Architectural Principles (Summary):**
    > 1.  **Directory Structure:** Respect the separation of concerns: `cmd/` (entrypoints), `internal/` (private logic), `services/` (microservices), `infra/` (IaC).
    > 2.  **Architectural Style:** **Agent Core + Go Business Logic.** Agent Core handles HTTP infrastructure (auth, rate limiting). The Go backend implements core business logic via MCP (Model Context Protocol).
    > 3.  **Frontend:** Strict TypeScript, component composition, and adherence to established UI patterns (shadcn/ui).
    > 4.  **Configuration:** Environment variables via `internal/config` (Go) or `VITE_MCP_*` (Frontend). No hardcoded secrets.
    > 5.  **Quality & Testing:** All code must pass `gatekeeper` checks. High test coverage is mandatory.

---

### 3. Core Research Areas
*Provide a detailed analysis for each of the following areas. Use, remove, or add to these examples as needed.*

#### 3.1. [AREA 1: e.g., Library Replacement Opportunities]
* **Objective:** `[e.g., Identify areas where custom-built logic can be replaced by well-established, pre-existing libraries to simplify code and improve robustness.]`
* **Key Activities:** `[e.g., 1. Analyze form handling logic and propose a standard. 2. Investigate custom utility functions that could be replaced by a library like lodash-es.]`

#### 3.2. [AREA 2: e.g., Code Deduplication and Abstraction]
* **Objective:** `[e.g., Identify duplicated business logic across tools and propose extraction into a shared utility package within internal/.]`
* **Key Activities:** `[e.g., 1. Analyze common data transformation patterns and propose new shared helpers. 2. Look for repeated validation logic that can be extracted into a custom validator in internal/constraints/.]`

#### 3.3. [AREA 3: e.g., New Feature Scaffolding]
* **Objective:** `[e.g., Propose a complete file and folder structure for a new 'GitHub' tool that adheres to all architectural rules.]`
* **Key Activities:** `[e.g., 1. Define the new tool's files in internal/tools/. 2. List the model files to be created in internal/schemas/. 3. Provide boilerplate for the new tool's registration in internal/bootstrap/tools_registration.go.]`

---

### 4. DOs/DON'Ts Compliance Verification

**Before finalizing recommendations, verify compliance with architectural rules (ADRs).**

> **Reference:** See `@docs/shared/tasks/active/2025-10-27-plugin-system-overhaul/Active/20-adr-alignment-guide.md` for the authoritative guide.

#### The "Big 6" Critical ADRs
*Violating these is a critical failure.*

1.  **ADR-041: Network-Transparent Error Handling**
    *   **Rule:** NEVER use `fmt.Errorf` or `errors.New` for crossing boundaries.
    *   **Requirement:** ALWAYS use `github.com/cockroachdb/errors`.
2.  **ADR-007: Clock Discipline**
    *   **Rule:** NEVER call `time.Now()`, `time.Sleep()` directly in business logic.
    *   **Requirement:** ALWAYS inject `clock.Clock` interface.
3.  **ADR-045 & ADR-022: Logger Injection**
    *   **Rule:** NEVER use `slog.Default()`, `log.Printf()`.
    *   **Requirement:** ALWAYS inject `*slog.Logger`.
4.  **ADR-011: Plugin Sentinel Errors**
    *   **Rule:** NEVER return ad-hoc string errors for known failure modes.
    *   **Requirement:** ALWAYS use defined sentinel errors (`catalog.ErrPrimitiveNotFound`).
5.  **ADR-019: Configuration Precedence**
    *   **Rule:** NEVER use `os.Getenv()` deep in the codebase.
    *   **Requirement:** ALWAYS load config at edge (`internal/config`) and inject.
6.  **ADR-085: Fx Dependency Injection Boundaries**
    *   **Rule:** NEVER use Fx (`go.uber.org/fx`) in CLI commands or deep packages.
    *   **Requirement:** Use direct instantiation (thin wrappers) for commands; Fx only for long-running servers (`bootstrap/`).

#### Compliance Matrix

| Recommendation | ADRs Checked | Compliant? | Notes |
| :--- | :--- | :--- | :--- |
| Approach A | ADR-019, ADR-007 | ✅ Yes | Uses config.Config + clock.Clock |
| Approach B | ADR-010 | ❌ No | Uses net/http in plugin code |
| Approach C | ADR-009 | ✅ Yes | Uses failsafe-go policies |

#### Non-Compliant Recommendations
**If ANY recommendation violates DOs/DON'Ts:**
1.  **Flag the violation:** `⚠️ WARNING: This approach violates ADR-XXX`
2.  **Explain why:** `Using os.Getenv() directly violates ADR-019.`
3.  **Provide compliant alternative:** `Inject config struct.`
4.  **Do NOT recommend the non-compliant approach.**

#### Research Conclusion Template
**Update conclusion to include compliance statement:**

```markdown
## Recommendation

Based on research and architectural compliance review:

**Recommended Approach:** [X]

**Compliance Summary:**
- ✅ Complies with ADR-019 (Configuration)
- ✅ Complies with ADR-007 (Clock Discipline)
- ✅ Complies with ADR-009 (Resilience)
- ✅ No gatekeeper violations

**Why this is the best choice:**
1. [Research-backed reason]
2. [Architectural compliance]
3. [Maintainability benefits]
```

---

### 5. Expected Output
* A structured report detailing findings and recommendations for each of the core research areas.
* For each recommendation, provide:
    * **Problem:** A description of the issue.
    * **Proposed Solution:** A clear plan for the refactor/implementation.
    * **File Impact:** A list of files to be created, modified, and deleted (referencing correct paths like `services/gideon-frontend/` or `internal/`).
    * **Code Example:** A brief, illustrative code snippet.
    * **Compliance Statement:** Verification that solution complies with all DOs/DON'Ts.

---

### 6. Final Instructions
* Prioritize clarity, structure, and actionable insights over verbosity.
* All proposals must be compliant with the **Architectural Guidelines** provided in Section 2 and **ADRs** in Section 4.
* Assume the audience is a technical engineer who will implement the plan.
