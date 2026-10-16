# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project targets [Semantic Versioning](https://semver.org/).

## [1.10.0](https://github.com/szTheory/relyra/compare/v1.9.0...v1.10.0) (2026-10-15)


### Features

* **73-17:** bound pure evidence mutations ([52db4cd](https://github.com/szTheory/relyra/commit/52db4cd6f17d6b36bd8691f9d4c1c94c66c699c9))
* **73-17:** capture deterministic owner snapshots ([b80b356](https://github.com/szTheory/relyra/commit/b80b35662cd0ae02213f00e6a360eb9dfadfa792))
* **73-18:** bind owners to tracked lexical files ([c549f81](https://github.com/szTheory/relyra/commit/c549f81925696694f2106222c408305786a6b579))
* **73-18:** enforce closed workflow path grammar ([03bd6aa](https://github.com/szTheory/relyra/commit/03bd6aad2d27436c765b103d319adbabddb3d87b))
* **73-21:** accept ready state in governance identity ([5969fd3](https://github.com/szTheory/relyra/commit/5969fd388db5e0b3810178ef747f1734bd436b41))
* **73-21:** keep lifecycle authority fail closed ([0b3444c](https://github.com/szTheory/relyra/commit/0b3444c898ddddda3869d58ddee03979c1514a7f))
* **73-22:** bind snapshots to governed inventory ([ba62ddb](https://github.com/szTheory/relyra/commit/ba62ddb7dcb839a9ae48feb30324cc34865411bf))
* **73-22:** serialize owner discovery by cache identity ([7924330](https://github.com/szTheory/relyra/commit/792433016ebd5ff8fb3335db648e231d36b33260))
* **73-24:** bind evidence ownership to repository ([fbf2ffe](https://github.com/szTheory/relyra/commit/fbf2ffe9978d932bb541b2e7709377d7196c2c87))
* **73-24:** close Mix test argv semantics ([b94078b](https://github.com/szTheory/relyra/commit/b94078b254dc13ae7a32f6856c38402e1cb83317))
* **73-24:** reopen current evidence blockers ([a564448](https://github.com/szTheory/relyra/commit/a56444828751848892400b62012afddfa778b3bd))
* **73-25:** classify completion boundaries and reject merges ([f736200](https://github.com/szTheory/relyra/commit/f73620035a60b34f4573a5f385f0e4af7b65c091))
* **73-25:** close task and acceptance parsing ([8101d7b](https://github.com/szTheory/relyra/commit/8101d7b428e21ddbc93e4b2ec9300d172c6d8927))
* **73-26:** stage source-bound reconciliation proof ([5fe6ff4](https://github.com/szTheory/relyra/commit/5fe6ff40f42d5dfc9003bd30df91b1646132e6c6))
* **73-31:** extend reconciliation proof ownership ([7bef0b6](https://github.com/szTheory/relyra/commit/7bef0b6ef6df14b26b751d88f51b11c2decdb0e7))
* **75-01:** add tenant-owned LedgerLoop scenarios ([5be3dfb](https://github.com/szTheory/relyra/commit/5be3dfb390b8883af61e859f28753502164ad38b))
* **75-02:** add deterministic trust history fixtures ([ce38976](https://github.com/szTheory/relyra/commit/ce38976bb952ac72f3c217a2692629df3861cade))
* **75-03:** add deterministic support incident evidence ([b0df9e0](https://github.com/szTheory/relyra/commit/b0df9e071b60c33315d0bab928ba3bb1f03d050b))
* **76-05:** schedule safe real IdP availability canary ([20e1338](https://github.com/szTheory/relyra/commit/20e133826831ac85e374a738253f5466ef8abd4f))
* **77-01:** enforce active docs policy and simplify onboarding ([79a247e](https://github.com/szTheory/relyra/commit/79a247e08da82e56a1147405bf15d20f45d2114c))
* **77-01:** refresh maintainer JTBD coverage map ([4adba15](https://github.com/szTheory/relyra/commit/4adba159cf8e2c853df7fec4fa8d236f3a4c16e2))
* **77-03:** validate tracked artifact ownership ([2d24fb8](https://github.com/szTheory/relyra/commit/2d24fb85cdfd7a826cb8cc6c27a3317c8ed07a99))
* **77-05:** reject mixed Markdown fence runs ([8ec84cc](https://github.com/szTheory/relyra/commit/8ec84cc392fa90c78a20e320b849531a320a1263))
* **77-05:** scan Markdown fences by closing run ([1b9b2df](https://github.com/szTheory/relyra/commit/1b9b2dfd731e0b73fdb647be62e6f05c737dd6d2))
* **79-01:** add read-only closeout inventory collector ([9c7c56c](https://github.com/szTheory/relyra/commit/9c7c56c8b9c017c502a7f97916471b17fb642c0a))
* **79-02:** add evidence-backed closeout and risk ledger ([815fbeb](https://github.com/szTheory/relyra/commit/815fbebe1f4fbb7491808549a8d149edd9829633))
* **79-03:** capture complete branch protection resource ([8d422d4](https://github.com/szTheory/relyra/commit/8d422d4c44ce7a4607e67f75333d758b652d0eb5))
* **79-05:** capture protection source conflicts ([1c7a28a](https://github.com/szTheory/relyra/commit/1c7a28afd1c5059880b342ac5d7b4ddba4919009))
* **79-06:** build fail-closed protection batch artifacts ([06dc3dc](https://github.com/szTheory/relyra/commit/06dc3dc3660be7cadaed5e8e4234e8b77729cfc4))
* **79-07:** add frozen publication and receipt gates ([2c2a8ad](https://github.com/szTheory/relyra/commit/2c2a8ada92628c8eb605b98582ea782a6fec5867))


### Bug Fixes

* **73-14:** close pull request event grammar ([6765e58](https://github.com/szTheory/relyra/commit/6765e58919fd0dab9d4d63024c47e2506a1511a1))
* **73-14:** close push event grammar ([a60f38e](https://github.com/szTheory/relyra/commit/a60f38e68f03bebe552732c2c6b339dc234045d4))
* **73-15:** govern history through review endpoint ([fdde29a](https://github.com/szTheory/relyra/commit/fdde29a1348dd084525f917822db0e7fdad03f54))
* **73-15:** require declarative remote mutations ([9648387](https://github.com/szTheory/relyra/commit/9648387db8042044355d46b2e3cb5c664ddd3d90))
* **73-27:** bind proof identity and authoritative replay ([0200702](https://github.com/szTheory/relyra/commit/02007021df0f4e879e3979abe30a512f389081e6))
* **73-28:** require top-level triggers and phase replay ([e43e853](https://github.com/szTheory/relyra/commit/e43e853b3eb4b34b160c9eef70aceda1021edb27))
* **73-29:** validate governance children and descendants ([fa0166d](https://github.com/szTheory/relyra/commit/fa0166d1a55db211998eb7629ce7f5d94e5e3caf))
* **73-30:** bind staged proof and closure validators ([daebd3e](https://github.com/szTheory/relyra/commit/daebd3ef1ea6e01d1c93a7663301f49aff528982))
* **73-30:** close seven findings with verified proof ([baa5b37](https://github.com/szTheory/relyra/commit/baa5b373c2143dbcfbd7b399c99ee27b71a10378))
* **73-30:** refresh proof for completed governance state ([464e68b](https://github.com/szTheory/relyra/commit/464e68bd5c80822d6a645ad79f901ded981b30b5))
* **73-30:** stage source-bound reconciliation proof ([cc8aee8](https://github.com/szTheory/relyra/commit/cc8aee81afd0a3b80d161e526431bc6bf87fda2a))
* **73-31:** track plans in reconciliation fixtures ([bb5f383](https://github.com/szTheory/relyra/commit/bb5f38360cf05f1d87874d859d499a7b1726a916))
* **73-33:** recognize completed phase lifecycle ([fa4bd4c](https://github.com/szTheory/relyra/commit/fa4bd4c7afa74e960bf99764b679055c38b1f380))
* **73:** bind final reconciliation to deterministic proof ([0cdc1bf](https://github.com/szTheory/relyra/commit/0cdc1bf0cc0af7007d76936cba36c21b8b58205e))
* **73:** revise plans based on checker feedback ([8f25e03](https://github.com/szTheory/relyra/commit/8f25e035a8043b6fdded037cfa0709d89914b22c))
* **74-04:** run every consumer smoke contract ([e8fe182](https://github.com/szTheory/relyra/commit/e8fe182388917f3a776acebadcb01502606da737))
* **75:** use valid trust history fixture certificates ([63b2868](https://github.com/szTheory/relyra/commit/63b2868fa7f005deeb01d933395460e55a0c1608))
* **76-01:** recover consumed intent for replay checks ([930c0e5](https://github.com/szTheory/relyra/commit/930c0e51fdff47b24f98a9cb446b9f4933ffb217))
* **76-01:** scope replay keys to resolved connection ([637d4d7](https://github.com/szTheory/relyra/commit/637d4d7d55b713a7edb09b302859ba8ec8a167fc))
* **77-04:** preserve posture on comment-only rationale ([7aa7633](https://github.com/szTheory/relyra/commit/7aa7633a57f269c0fc91ac87ce1fc75b1e60aad1))
* **77-07:** scope policy scan to actionable inputs ([6197896](https://github.com/szTheory/relyra/commit/6197896ae4b3f5c5fdbd0396669271f258e0f916))
* **77:** make follow-up runnable and resolve research scope ([d01bb14](https://github.com/szTheory/relyra/commit/d01bb141f1e4bcc009b8a7ab3b77d1aba3db59a7))
* **77:** repair plan verification contracts and provenance ([7acfafe](https://github.com/szTheory/relyra/commit/7acfafee652b6495078df81d67ca9ed72fcaf528))
* **77:** revise follow-up plan from checker feedback ([4564af3](https://github.com/szTheory/relyra/commit/4564af33bd4af0580feae207d07daceda60caf43))
* **77:** unblock G-1 gap plan dependency ([821ddcf](https://github.com/szTheory/relyra/commit/821ddcfcdc25f5c332444a6f93f383106f60634f))
* **77:** verify signature posture from recorded source history ([fab4fba](https://github.com/szTheory/relyra/commit/fab4fba97480d9d33f9f9d4abdb15ff1440d0577))
* **78-07:** accept canonical Phase 73 digests ([8c79d50](https://github.com/szTheory/relyra/commit/8c79d50a96d576fd64001346f63b8446973ccb4a))
* **78-07:** canonicalize cold workspace temp root ([48523e1](https://github.com/szTheory/relyra/commit/48523e1a6693d635ba865ccd7ee8f2681f36bd15))
* **78-07:** make LedgerLoop cold checks deterministic ([e67aa06](https://github.com/szTheory/relyra/commit/e67aa06b58b867711f9a7e0078cf05190ab4a082))
* **78-07:** prepare fresh ledgerloop test metadata ([9bacc40](https://github.com/szTheory/relyra/commit/9bacc4056bb64bee98c949475f4f8dd2dc424dce))
* **78-07:** preserve isolated node shim resolution ([c2261e3](https://github.com/szTheory/relyra/commit/c2261e3e972d3e5e8aa4e84f83eb7502fb6ca78a))
* **78-07:** preserve tools in isolated cold runner ([46ec90f](https://github.com/szTheory/relyra/commit/46ec90f0728abbfd24db39fd839809b279951fa9))
* **78-07:** stabilize clean-state test contracts ([8de7061](https://github.com/szTheory/relyra/commit/8de70612de7827ec58d3066229144d1b4a8133a2))
* **78-08:** accept eight plans and exact provenance ([aa2ef61](https://github.com/szTheory/relyra/commit/aa2ef61013ce6debb111daa3603aece27666f001))
* **78-08:** pin current Release Please action ([4da3b4a](https://github.com/szTheory/relyra/commit/4da3b4a9464ddc9da5c119b1459614fdd54b24f6))
* **78-09:** bound generated report digest exclusion ([7e7a2c0](https://github.com/szTheory/relyra/commit/7e7a2c0a8acc2060f442ca7e8902b8a32bd445e2))
* **79-01:** bind lane evidence to owning checks ([08557e1](https://github.com/szTheory/relyra/commit/08557e1957009ce4ceb40df6a71509d6e01187a2))
* **79-01:** fail closed on partial inventory evidence ([a8f2236](https://github.com/szTheory/relyra/commit/a8f22365f7fc4471fd7747f8c0859cb4cd9877f5))
* **79-01:** restrict mandatory lane owners ([2ea11aa](https://github.com/szTheory/relyra/commit/2ea11aa22a5301e90d61a8661134f67f1d48507d))
* **79-01:** retain canary check evidence ([ac29b5d](https://github.com/szTheory/relyra/commit/ac29b5d3aca8e9833258fb8512e987bec3e2220b))
* **79-03:** classify GSD execution state ([28399a1](https://github.com/szTheory/relyra/commit/28399a1edd88a35e95c5b6f4d0744983e918ce39))
* **79-03:** classify protection proposal artifacts ([826fd57](https://github.com/szTheory/relyra/commit/826fd570654b2d3e8b695db2f224901af1a69438))
* **79-05:** bind final inventory evidence ([4088111](https://github.com/szTheory/relyra/commit/40881114d961b6f45e62173b8ea316e54472280e))
* **79-06:** preserve capture blockers and current evidence ownership ([9dcb654](https://github.com/szTheory/relyra/commit/9dcb654669a0d4edc92cf6b187c46adf7e9f9d48))
* **79-06:** reject malformed protection captures ([6ae1735](https://github.com/szTheory/relyra/commit/6ae1735b3be00c50500a648b1f4ffb2152b613da))
* **79-07:** accept source lifecycle in isolated candidate ([7715d4c](https://github.com/szTheory/relyra/commit/7715d4c7f99813699520c5730b56f9ef7b450861))
* **79-07:** bind proposal to main branch ([bdc382d](https://github.com/szTheory/relyra/commit/bdc382d630637f893dd06523dd215e236db0a982))
* **79-07:** keep transaction verifier candidate-compatible ([c83ecf2](https://github.com/szTheory/relyra/commit/c83ecf23c2d3bae81471d4d6e39f2c56267f1096))
* **79-07:** preserve exact dirty worktree paths ([a0e197c](https://github.com/szTheory/relyra/commit/a0e197c462447b620057b0377670a3938b2eabbd))
* **79-255:** carry bounded receipt diagnostics repair ([82cb153](https://github.com/szTheory/relyra/commit/82cb153eb9f7c9bfa4c38c32c913e742558d66e4))
* **79-255:** clean known contract probe paths ([0cf136d](https://github.com/szTheory/relyra/commit/0cf136d26beaedda9037b1898a8b2dc28c74e165))
* **79-386:** resolve gsd-tools portably in the Phase 79 plan contract ([99ccbcc](https://github.com/szTheory/relyra/commit/99ccbcc1281fad2d1cb2a591dc973cf40f3633d7))
* **79:** classify owned closeout inventory paths ([01afe09](https://github.com/szTheory/relyra/commit/01afe099c0045243a38715f861d7bb3b89c8bd29))
* **79:** CR-01 bind mandatory lanes to owner runs ([39aefb3](https://github.com/szTheory/relyra/commit/39aefb3b104c050988caabe5766f9450d2993524))
* **79:** CR-01/CR-02/CR-03 bind checks to latest owner jobs ([768f60a](https://github.com/szTheory/relyra/commit/768f60addd4ab7f3675292b673ee166be152f5b3))
* **79:** CR-01/CR-02/WR-01 validate source-bound inventory evidence ([0cd8b18](https://github.com/szTheory/relyra/commit/0cd8b188578b13f5728bcffc96fa8ca4f0627ed4))
* **79:** handle GitHub evidence edge cases ([19fd09b](https://github.com/szTheory/relyra/commit/19fd09bf0f9ec26521d7aa99280272b4300446f9))
* **79:** keep local ownership disposition current ([79ca3f8](https://github.com/szTheory/relyra/commit/79ca3f86720463aade7b2be6884612426aa910be))
* **79:** WR-01 validate origin host before inventory ([f0ae565](https://github.com/szTheory/relyra/commit/f0ae565b141a3423054ba0528dae803e9bc9cc7d))
* **79:** WR-02 paginate commit statuses with provenance ([dc3ef94](https://github.com/szTheory/relyra/commit/dc3ef945b0b6f9a732cd2641f44eb62bfdff67f6))
* **ci:** align cold producer environments ([767c3a5](https://github.com/szTheory/relyra/commit/767c3a5cbfa95db787e47d11fda3f00b6b6ff51c))
* **ci:** bound browser and canary failure artifacts ([88bfb84](https://github.com/szTheory/relyra/commit/88bfb84734cf40d0aa03c60cb923b38975f67839))
* **ci:** check out the Phase 78 workspace with readable file modes ([603dd64](https://github.com/szTheory/relyra/commit/603dd64305f104c931d175ae8fab3083bd117c00))
* **ci:** isolate audit shutdowns and restore the real Hex gate ([f0b4e28](https://github.com/szTheory/relyra/commit/f0b4e287fc7fca43936cd1d23ac71a1ab418c71f))
* **ci:** keep the Phase 78 clone log out of the diagnostics bundle ([3655c20](https://github.com/szTheory/relyra/commit/3655c20c1f784cf72bc07654abdced631cb81c2c))
* **ci:** load nested demo test metadata on fresh runners ([835a4e3](https://github.com/szTheory/relyra/commit/835a4e3225262367ad0104dc42d9af3ce16fd86c))
* **demo:** honour PGPORT in the LedgerLoop repo config ([f54b2de](https://github.com/szTheory/relyra/commit/f54b2de6fd2a293035926150a62110aa23e1d73d))
* **demo:** link login receipts to verified tenant connections ([83cd400](https://github.com/szTheory/relyra/commit/83cd40010bdff00a8591e0b587ec4bcd93f2c911))
* **deps:** accept test-only bandit advisory GHSA-69m6-wcv4-rwcf until a fix ships ([34f4e1f](https://github.com/szTheory/relyra/commit/34f4e1f3a4b8f310a54c23a99bdb2d68f7b917a7))
* **deps:** patch Postgrex, LiveView and lazy_html advisories ([8e77a2b](https://github.com/szTheory/relyra/commit/8e77a2be63954b48abd969282f28f01070753ee2))
* **deps:** update bandit to 1.13.0 and drop its advisory exception ([7ceee68](https://github.com/szTheory/relyra/commit/7ceee68262571cbad8b3c329bebabafab11d33b7))
* **deps:** update decimal to 3.2.0 for EEF-CVE-2026-97853 ([cdb4407](https://github.com/szTheory/relyra/commit/cdb44071822a5a6e0fb6574f68d214c6c080ec55))
* **deps:** update Mint to 1.10.2 for HTTP parser advisories ([bd292c9](https://github.com/szTheory/relyra/commit/bd292c95f765225187af4233522e4f5a8f474dcf))
* **governance:** align active phase acceptance gate ([b7f9b54](https://github.com/szTheory/relyra/commit/b7f9b54b5d7ef6fa0465e2d967fe416ad27f4925))
* **test:** stop test repo query logs from leaking fixture PEMs into Phase 78 diagnostics ([d74b7a4](https://github.com/szTheory/relyra/commit/d74b7a4b35102a8e170586597d268dea15f62e83))


### Performance Improvements

* **73-24:** batch governed input tracking checks ([cff012d](https://github.com/szTheory/relyra/commit/cff012d2d2cb52a65e7356cc0c498399e53f98c7))
* **ci:** stabilize evidence contract execution ([a47dfe1](https://github.com/szTheory/relyra/commit/a47dfe1655cf9161d6c05ab0eef0531958dbdc64))

## [1.9.0](https://github.com/szTheory/relyra/compare/v1.8.1...v1.9.0) (2026-08-28)


### Features

* **64-01:** add public testing fixture helper plumbing ([8ca3d10](https://github.com/szTheory/relyra/commit/8ca3d109aac171f92c1f7b9d3055d9eb821bb6ce))
* **64-01:** implement signed success testing fixture ([7463728](https://github.com/szTheory/relyra/commit/7463728a248b40e62da6354d2faebc5e282de01c))
* **64-02:** implement public negative testing fixtures ([465a6b4](https://github.com/szTheory/relyra/commit/465a6b4bc254ee0b1f29be1e736c56d8cccd3602))
* **64-03:** add optional Phoenix fixture dispatch helper ([3e48cb2](https://github.com/szTheory/relyra/commit/3e48cb2c4576a1ce0fcb5802f8bbb8aa3624061f))
* **68-01:** add docker-entrypoint.sh with lock-hash gate and ecto ordering ([60765ad](https://github.com/szTheory/relyra/commit/60765ad247789150bdf4a604938aa08d843f29ab))
* **68-01:** add Dockerfile.dev with cached dep layer and pinned base ([ba263d0](https://github.com/szTheory/relyra/commit/ba263d0b646af0e77c25c1e11d94a77a886d0f46))
* **68-01:** add repo-root .dockerignore with build-context exclusions ([d088f34](https://github.com/szTheory/relyra/commit/d088f3490f6231d4b3b2049977108fb219c159b9))
* **68-02:** add top-level config :phoenix_live_reload :fs_poll block for cross-mount live reload ([b31b3cd](https://github.com/szTheory/relyra/commit/b31b3cd4820ddd2d841246f53d88ca4683961e4c))
* **68-02:** wire demo_app to Dockerfile.dev with named-volume masking ([eee4f36](https://github.com/szTheory/relyra/commit/eee4f360075215ba3a7684f4a6403d6f06cb4ff9))
* **69-01:** configure explicit demo origins ([b77c2e1](https://github.com/szTheory/relyra/commit/b77c2e1bfed2b8766aa33208dd16dc86a340d838))
* **69-01:** split solo Compose ingress ([d1be9bc](https://github.com/szTheory/relyra/commit/d1be9bc5903de64bb1a901c490edf5d28a252996))
* **69-02:** add neutral shared Traefik project ([ea30f04](https://github.com/szTheory/relyra/commit/ea30f04171a58ca5131ec9c5c9f0d5b167fb22bc))
* **69-02:** route demo through shared proxy ([4af92f2](https://github.com/szTheory/relyra/commit/4af92f29841f27dfec8317c574df652624697ced))
* **70-01:** prove Keycloak login through proxy ([600f4c9](https://github.com/szTheory/relyra/commit/600f4c9277a936e42db3eaa1c6be79d2cede2611))
* **70-02:** reconcile Keycloak provisioning safely ([30625b1](https://github.com/szTheory/relyra/commit/30625b106d93a8c5bd5cf43b2073b9c84ac6ca8c))
* **70-02:** reconcile Keycloak signing-key rotation ([23a7737](https://github.com/szTheory/relyra/commit/23a77373c1dc65ff3f4bb84773714042397983ef))
* **70-03:** harden Keycloak proof lifecycle diagnostics\n\n- Recreate only harness-owned realm state for each run\n- Classify redacted lifecycle failures by trust-proof layer\n\nCo-Authored-By: Codex &lt;noreply@tool.example&gt; ([00aa415](https://github.com/szTheory/relyra/commit/00aa415609d6072cea7b1a33b072a64d2a121fbe))
* **70-03:** verify Keycloak split-horizon renders\n\n- Check default and RELYRA_HOST override proxy contracts\n- Bind every realm browser endpoint to the public host input\n\nCo-Authored-By: Codex &lt;noreply@tool.example&gt; ([959a1b1](https://github.com/szTheory/relyra/commit/959a1b1261e4e5cfd7a8768c167440c5a8449582))
* **70-04:** gate Keycloak login affordance by trust state ([8ec33dd](https://github.com/szTheory/relyra/commit/8ec33dd770b1b5fac047e914b179d1f9f0773a4b))
* **70-04:** show durable verified sign-in receipt ([5c2dfa5](https://github.com/szTheory/relyra/commit/5c2dfa585098a751289fdcbdddea7ab89b27a258))
* **70-05:** prove the public Keycloak trust journey ([643d388](https://github.com/szTheory/relyra/commit/643d388433b93341b301307b76009adea3426e74))
* **70-06:** apply Keycloak descriptor candidate once ([d933cba](https://github.com/szTheory/relyra/commit/d933cbacdfc25b2de5a5c042eb62e4a5b019695b))
* **70-08:** authenticate Keycloak trace proof ([fe00a8e](https://github.com/szTheory/relyra/commit/fe00a8eaa4901813e843876b26f1c5e8cdbec81d))
* **70-08:** protect demo admin routes with Basic auth ([46e0078](https://github.com/szTheory/relyra/commit/46e0078642fe02c4d4f20ec18322cf4a1141d9b0))
* **70-09:** atomically finalize Keycloak identity mapping ([5d33934](https://github.com/szTheory/relyra/commit/5d339349a4476f53090fbe413d14a51a0a0468dd))
* **70-13:** add accessible visual login trace fixture ([7f8d6ca](https://github.com/szTheory/relyra/commit/7f8d6ca8979edf7d6982fc51bf8e4f805f81a649))
* **70-14:** add credential-safe trace visual gate ([87708d6](https://github.com/szTheory/relyra/commit/87708d6d007ed51b233c06588da0c149c9c6b114))
* **71-01:** add canonical demo launcher ([b768408](https://github.com/szTheory/relyra/commit/b7684086a0eefe6d44ba38364b7d133b64a0f920))
* **72-02:** converge demo documentation routers ([2d499d5](https://github.com/szTheory/relyra/commit/2d499d58bced17e3d2d57db9b9fe234d5db5b181))
* **72-02:** refresh LedgerLoop Docker evaluator route ([3b550c8](https://github.com/szTheory/relyra/commit/3b550c8945910cbf257b307b0f49789ee4c690ab))
* **72-03:** add validated Keycloak Fleet launcher ([e4fe72e](https://github.com/szTheory/relyra/commit/e4fe72e08bc4098752a65958ca64c4fe33678fc3))
* **72.1-01:** render scoped SAML setup URLs ([7733383](https://github.com/szTheory/relyra/commit/7733383e2eaca219e401f22145ef29323187709d))
* **72.1-02:** forward demo admin credentials ([3194477](https://github.com/szTheory/relyra/commit/31944770e9c388406613232e2972c4bf42a3424c))
* **72.1-04:** prove credentialed Keycloak trace access ([0ec49a8](https://github.com/szTheory/relyra/commit/0ec49a8677d77ba0e60178c2e1b374c3263c103b))
* **launcher:** automate Phase 71 acceptance ([80dc15d](https://github.com/szTheory/relyra/commit/80dc15d80020d918e018414a6d56bc1578443239))


### Bug Fixes

* **64-03:** remove Phoenix token from core testing docs ([552b81b](https://github.com/szTheory/relyra/commit/552b81bbf6b245b80791af215ef9b1ee15f380ef))
* **64:** guard wrong-audience testing fixture ([3b193d7](https://github.com/szTheory/relyra/commit/3b193d7991569f742f3e26bbd188c4999b49a2d5))
* **64:** revise plans based on checker feedback ([c181481](https://github.com/szTheory/relyra/commit/c1814813f75b632c7ae4a40c4646729534f2fcc2))
* **67-02:** assert assigned CVE backfill ([fe9437f](https://github.com/szTheory/relyra/commit/fe9437fefa7f8cf3f8e80763b23dcbcc3ca325a0))
* **67:** address code review warnings ([6cfcb1e](https://github.com/szTheory/relyra/commit/6cfcb1eed23315011874b1a416b17e4192262974))
* **70-07:** prevent Keycloak browser artifact capture\n\n- disable sensitive Playwright attachments\n- isolate and remove browser output before diagnostics\n\nCo-Authored-By: Codex &lt;noreply@tool.example&gt; ([7862c75](https://github.com/szTheory/relyra/commit/7862c750472049e33d9ccb064f96813e4c92d954))
* **70-07:** retain only validated Keycloak diagnostics\n\n- redact into private staging before promotion\n- discard all uncertain diagnostic candidates\n\nCo-Authored-By: Codex &lt;noreply@tool.example&gt; ([52255aa](https://github.com/szTheory/relyra/commit/52255aaa43559d2e2ad3615b7fd6cb1bb6e0d4fa))
* **70-10:** reject qualified diagnostic XML ([b63e8e6](https://github.com/szTheory/relyra/commit/b63e8e64d028c586c957a9b8fa1cadf9781860cd))
* **70-11:** focus Keycloak proxy acceptance gate ([7956fbb](https://github.com/szTheory/relyra/commit/7956fbb68ea9e2d6ecbcd557f48a4691d49112ba))
* **70:** CR-01 reject mismatched Sarah identity mapping ([ce82276](https://github.com/szTheory/relyra/commit/ce82276815dfaa7841bf4c52d35b535a886bc530))
* **70:** CR-02 confine Keycloak diagnostic cleanup ([dc8b39b](https://github.com/szTheory/relyra/commit/dc8b39b4b7ef90e9d70fce0c5808f36dc9060fd7))
* **72-05:** advance documentation ordering cursor ([1ec503c](https://github.com/szTheory/relyra/commit/1ec503c10ab10c5c224befa5410fa3fab17cced4))
* **72-05:** carry configured Solo port through recovery ([edc6172](https://github.com/szTheory/relyra/commit/edc6172ba34c01c252cc6a231416c2a6b125e47c))
* **binding:** retain SAML redirect padding ([89f2220](https://github.com/szTheory/relyra/commit/89f22208603746add012817ce90d6a2c5bca8600))
* **ci:** isolate admin browser smoke ([0810305](https://github.com/szTheory/relyra/commit/0810305abfa4bf994a3e6c747d5624a1ca81e44c))
* **demo:** allow cold container startup ([d158d8e](https://github.com/szTheory/relyra/commit/d158d8e01207dba12a2a95d14f6b1ece5d8e3d0c))
* **deps:** patch Req transport graph advisories ([291396b](https://github.com/szTheory/relyra/commit/291396bb9761360d16ad62140110afac52feb80a))

## [1.8.1](https://github.com/szTheory/relyra/compare/v1.8.0...v1.8.1) (2026-06-14)


### Bug Fixes

* **brandbook:** integrated typemark as primary logo + dark-mode rendering ([#38](https://github.com/szTheory/relyra/issues/38)) ([2156562](https://github.com/szTheory/relyra/commit/215656260bd51ce758e8dd62b7b774875506c76b))

## [1.8.0](https://github.com/szTheory/relyra/compare/v1.7.0...v1.8.0) (2026-06-14)


### Features

* **demo:** FakeIdP browser-login proof + hardening (Phase 57/57.1) ([#35](https://github.com/szTheory/relyra/issues/35)) ([9b72d1e](https://github.com/szTheory/relyra/commit/9b72d1ec3f7d650002af176f7a3395dc3ea29db7))

## [1.7.0](https://github.com/szTheory/relyra/compare/v1.6.0...v1.7.0) (2026-06-13)


### Features

* v1.7 Adoption Evidence Demo (LedgerLoop runnable demo app) ([#31](https://github.com/szTheory/relyra/issues/31)) ([b66722d](https://github.com/szTheory/relyra/commit/b66722d0aa73e17fc408cfab7172afc62841bd78))

## [1.6.0](https://github.com/szTheory/relyra/compare/v1.5.4...v1.6.0) (2026-05-29)


### Features

* **adoption:** Phase 50 golden host journeys and Keycloak CI lane ([b21bdbb](https://github.com/szTheory/relyra/commit/b21bdbb254163983da179304455b58d7d35460fe))
* **adoption:** Phase 50 golden host journeys and Keycloak CI lane ([fb105da](https://github.com/szTheory/relyra/commit/fb105da4d8f60de890014b5f46b2eba19dbe927f))


### Bug Fixes

* **adoption:** CI warnings and Keycloak SSO redirect binding ([83f9b90](https://github.com/szTheory/relyra/commit/83f9b90028be15279d1592dd9c1bb28628d50c09))
* **adoption:** follow Keycloak SSO redirects when fetching login form ([19fbb26](https://github.com/szTheory/relyra/commit/19fbb26e11ffb15e796639c445ea7ba8511a8ff7))
* **adoption:** green Keycloak external IdP lane and real IdP crypto interop ([d48871a](https://github.com/szTheory/relyra/commit/d48871a22e501f6141219adaa096789d6cc85d60))
* **adoption:** stabilize Keycloak login fetch without form pre-check ([45e1d1e](https://github.com/szTheory/relyra/commit/45e1d1efb1d278439b5aee25f61aa718273d00e6))
* **adoption:** use valid guard in Keycloak redirect URL helper ([18f78ae](https://github.com/szTheory/relyra/commit/18f78aeeff72ca7afd6665f7eb2b34b1b0d2f10f))
* **security:** align KeyInfo corpus with rogue-outside-Signature policy ([7846892](https://github.com/szTheory/relyra/commit/78468929a8f152dcb19000cefc8789a7e799dab3))

## [1.5.4](https://github.com/szTheory/relyra/compare/v1.5.3...v1.5.4) (2026-05-28)


### Bug Fixes

* **ci:** auto-dispatch Hex publish after release-please automerge ([e50dfd5](https://github.com/szTheory/relyra/commit/e50dfd59fd76938842ca637813a04f7011d704d2))
* **ci:** auto-dispatch Hex publish after release-please automerge ([39bbc21](https://github.com/szTheory/relyra/commit/39bbc21a5ca22484f25b866e45041fda973d0c23))

## [1.5.3](https://github.com/szTheory/relyra/compare/v1.5.2...v1.5.3) (2026-05-28)


### Bug Fixes

* **ci:** grant actions:write for release-please PR dispatch ([e32d828](https://github.com/szTheory/relyra/commit/e32d8282f47971770d7382ca9f59de63f33a536a))
* **ci:** grant actions:write for release-please PR dispatch ([ecf2736](https://github.com/szTheory/relyra/commit/ecf2736b9185d3a46bf4723bea9e04ac53978c58))
* **ci:** parse spaced security-gates check names on release PRs ([099b92b](https://github.com/szTheory/relyra/commit/099b92b098dc02b9b9714afce7a2372cc99dd8ea))
* **ci:** parse spaced security-gates check names on release PRs ([adabc13](https://github.com/szTheory/relyra/commit/adabc1381ce118d71f85eb1061264ddac5dec7cb))
* **ci:** tolerate gh pr checks exit when no checks yet ([fbef01c](https://github.com/szTheory/relyra/commit/fbef01cf9c3f2e363d3a73eecf7c37681274b079))
* **ci:** tolerate gh pr checks exit when no checks yet ([98606d2](https://github.com/szTheory/relyra/commit/98606d2f0b6501b4ab7684802569dfff26432307))
* **docs:** note hands-off release path in getting started ([0f6d758](https://github.com/szTheory/relyra/commit/0f6d7588cf9286f1f457c782c63592e35c9e7214))
* **docs:** note hands-off release path in getting started ([f19d239](https://github.com/szTheory/relyra/commit/f19d2392c5b5a035c82c5466a6a7d0490cd7f3af))

## [1.5.2](https://github.com/szTheory/relyra/compare/v1.5.1...v1.5.2) (2026-05-28)


### Bug Fixes

* **test:** isolate replay store and warm FakeIdP keypair ([3635c5c](https://github.com/szTheory/relyra/commit/3635c5c4a8900ebd4bd4733b01b480637c258bc7))
* **test:** isolate replay store and warm FakeIdP keypair ([d2bb6bf](https://github.com/szTheory/relyra/commit/d2bb6bf6c957162598d47e2e31657be92fea646d))

## [1.5.1](https://github.com/szTheory/relyra/compare/v1.5.0...v1.5.1) (2026-05-28)


### Bug Fixes

* **ci:** gate Hex publish on mix qa and enforce branch protection ([7303b36](https://github.com/szTheory/relyra/commit/7303b3659883458102e97d691540736b3ce2ff64))
* **ci:** release-please trigger for 1.5.1 ([15efe67](https://github.com/szTheory/relyra/commit/15efe677a837c61364e00abf89d1b1a472704449))

## [1.5.0](https://github.com/szTheory/relyra/compare/v1.4.0...v1.5.0) (2026-05-28)


### Features

* **45-01:** add mix verify.release_parity for Hex vs tag path-set diff ([7ca46c4](https://github.com/szTheory/relyra/commit/7ca46c461dee37997330859ead5e045110f441a4))
* **45-02:** add verify-parity.sh milestone gate wrapper ([227a3c2](https://github.com/szTheory/relyra/commit/227a3c23d5583c5f78534a75c93e1c92a0dc1577))
* **49-01:** add scope boundary section to conformance generator ([93418a6](https://github.com/szTheory/relyra/commit/93418a64461ed0344adfa6bced4961c614f38f04))
* **49-01:** flip ENC manifest row from deferred to pass ([f865174](https://github.com/szTheory/relyra/commit/f865174995964a4cc19e77c4148c13da053a662d))
* **docs:** add README Quick Look preset snippet (DX-01) ([65bcf93](https://github.com/szTheory/relyra/commit/65bcf93f96727ba6e96c89da92226a5144f71ec2))
* **docs:** job-shaped overview hub and batteries dedupe (DX-03) ([00937be](https://github.com/szTheory/relyra/commit/00937befa5512c107f0faf1f98c5a1021d171a5a))
* **install:** auto-inject saml_routes on single Phoenix router (DX-02) ([ca632bd](https://github.com/szTheory/relyra/commit/ca632bd9defed9449118b2f5bdd9ea0a2d1913b7))

## [1.4.0]

Hex publishes **1.4.0** directly from **1.2.0** with no intermediate **1.3.0** Hex release for adopter clarity — one install line `{:relyra, "~> 1.4"}` receives Advanced Federation, Single Logout, and the login trace UI. The `[1.3.0]` section below is changelog archaeology for the v1.3 milestone only, not a skipped Hex version adopters must hunt for.

### Added

- **Single Logout:** `SessionAdapter` session-index hooks; SP- and IdP-initiated logout via `Relyra.consume_logout/3`; HTTP-Redirect and HTTP-POST bindings; strict logout validation pipeline (`Parse → Verify → Replay → Execute`); `LogoutRequest`/`LogoutResponse` on the same `SaxyTree` parse path as login.
- **Logout operator guide:** `guides/recipes/logout.md` — browser cookie caveats, durable session prerequisites, absolute-timeout boundaries, and host-owned session-index linkage.
- **Incident playbook:** `guides/operations/incident_playbook.md` — six Triage→Diagnose→Recover scenarios with evidence surfaces for telemetry, audit, and login trace.
- **Troubleshooting decoder:** `guides/troubleshooting.md` — 78 typed SAML error atoms across seven trust-pipeline buckets, kept in sync with the codebase.
- **Login trace LiveView:** `ConnectionTraceLive` at `/relyra/admin/connections/:connection_id/trace` — expandable step timeline from audit rows and telemetry.
- **Headless login trace:** `mix relyra.trace` for the same redacted step timeline without opening the browser.
- **Shared trace export:** `Relyra.LoginTrace.Export` redacts login-trace rows consistently for LiveView and CLI.
- **Publish hygiene:** SP metadata attribute escaping; `test_support` excluded from production compile and Hex tarball; encrypted-assertion wire extraction uses parse-tree byte spans only; README and preset documentation aligned with shipped presets.

### Changed

- Trust audit timeline excludes `domain: :login` rows (login traces separate from trust mutations).
- `LoginResult.validation_trace` populated on successful consume via `LoginTrace` telemetry handler.
- Production `elixirc_paths` uses explicit lib file list (excludes `test_support`).

### Security

- **Logout crypto:** XMLDSig verification before session termination; redirect signatures verified against raw query octets; replay protection on logout messages.
- **Login trace redaction:** security tests ensure LiveView and CLI never render raw XML, PEM, certificate bodies, signature values, or key material.
- **Metadata XSS defense-in-depth:** interpolated SP metadata attributes are XML-escaped before publish.
- **One trust path for encrypted assertions:** wire extraction uses parse-tree byte spans only — no parallel regex locator on the auth boundary.

## [1.3.0]

This section records the v1.3 Advanced Federation milestone only — **no Hex release at 1.3.0** (historical record).

### Added

- **Encrypted assertions (ENC-01/02):** `KeyResolver` behaviour + `KeyResolver.Default` (SP private key from app config only); `Relyra.Security.XMLEnc.decrypt/3` with RSA-OAEP + AES-GCM behind `AlgorithmPolicy`; decrypt-then-reparse pipeline stage in `ValidationPipeline` (`:decrypt_assertion` pre-stage); cleartext+encrypted ambiguity guard (`:ambiguous_assertion` before crypto); SP metadata encryption `KeyDescriptor`; 7-fixture ENC-01 adversarial corpus in `mix ci.security`.
- **Signed AuthnRequests (AUTHN-01):** HTTP-Redirect query signing (`sign_redirect_query/3` raw-octet invariant); `sign_authn_requests` connection toggle; SP metadata `AuthnRequestsSigned` + signing `KeyDescriptor`; ADFS provider preset + `guides/recipes/adfs.md`; 5-fixture AUTHN-01 adversarial corpus in `mix ci.security`.
- **AlgorithmPolicy + schema:** Key-transport and content-encryption enforcement; RSA-PKCS1v1.5 blocked; AES-CBC blocked by default with time-boxed escape hatch; GCM auth-tag length guard; cert `party`/`use` columns; `sign_authn_requests` migration.
- **Documentation (DOCS-02):** `guides/recipes/generic_saml.md` — SP/IdP metadata reference, decoder tables for IBM Security Verify, CyberArk, Oracle Access Manager, PingFederate, CA SiteMinder; security checklist, debugging flow, cert rotation.
- **Documentation (DOCS-03):** `guides/identity_mapping_and_provisioning.md` — NameID vs attribute mapping patterns, JIT decision tree, `UserMapper` examples, SCIM non-goal.

### Changed

- `PureBeam.build_parsed_doc/1` tolerates encrypted-only Responses pre-decrypt (`encrypted_pending` path) without weakening cleartext gates.
- SP metadata build order: signing + encryption `KeyDescriptor`s before ACS (schema-valid).

### Security

- **Decrypt-then-reparse invariant:** decrypted bytes MUST pass `PureBeam.parse_safely/2` AND `Signature.do_verify/4` before identity fields — CVE-2025-54419 class read-before-verify rejected by adversarial corpus.
- **Single opaque `:decryption_failed`** for all decryption failure modes (no padding oracle via distinct atoms).
- **Document `KeyInfo` ignored** for decryption key material — configured `KeyResolver` only.
- **Ambiguity guard:** cleartext + encrypted assertion → `:ambiguous_assertion` pre-crypto (CVE-2026-2092 class).
- **Redirect AuthnRequest signing:** golden corpus enforces no re-serialization before sign; ADFS `+`-encoding variant covered.
- **AlgorithmPolicy:** RSA-OAEP SHA-256 URI blocked pending OTP support; zero new Hex deps for XML-Enc (OTP stdlib only).

## [1.2.0](https://github.com/szTheory/relyra/compare/v1.1.0...v1.2.0) (2026-05-25)


### Features

* **28-01:** implement SaxyTree handler with ns stack + 3 normalizations ([8738532](https://github.com/szTheory/relyra/commit/87385326a3c3d34c758be6e6ed9554aeee26816c))
* **28-02:** enveloped-sig transform pruning + PrefixList forced render + transform allowlist ([ae9f16f](https://github.com/szTheory/relyra/commit/ae9f16feb5f7a201b05c1a99500ca2240c2fdd69))
* **28-02:** implement exclusive C14N 1.0 serialization core ([b666926](https://github.com/szTheory/relyra/commit/b666926e17674916ca77f4cc0938aaa907a161be))
* **28-03:** bind exact tree node + delegate canonicalize/2 to the C14N engine ([5565df5](https://github.com/szTheory/relyra/commit/5565df50d7b68abdaad88fe8db6f556d8458c106))
* **28-03:** route parse_safely onto the saxy tree, retire regex extractors ([915d460](https://github.com/szTheory/relyra/commit/915d4604b0daa89e39279aa03acb04aa970dc0b1))
* **29-01:** add ordered content field to SaxyTree.Node (D-09) ([4411f91](https://github.com/szTheory/relyra/commit/4411f91ea1785c9ba99d46e58b4c90f122d7bb90))
* **29-02:** add AlgorithmPolicy.digest_atom_for_signature_method/1 (RSA→atom, ECDSA fail-closed) ([e63216e](https://github.com/szTheory/relyra/commit/e63216eafbee4e463e6e3995ef78160d9ed1aba3))
* **29-02:** surface D-02 fields (SignedInfo node, base64 Digest/SignatureValue) per candidate ([5d1cfc9](https://github.com/szTheory/relyra/commit/5d1cfc9a41c732be0f360175781d319c49e3fec0))
* **29-03:** wire real XMLDSig crypto into the [candidate] arm (D-01) ([2e45689](https://github.com/szTheory/relyra/commit/2e456897af3158c175bb490ce7fc51d6241c8922))
* **29-04:** build genuine XMLDSig test-signer (D-11) ([c45864f](https://github.com/szTheory/relyra/commit/c45864fd00b3d6a201b184da21453a53626c0bde))
* **29-05:** add metadata-root signed-candidates producer in pure_beam ([502417f](https://github.com/szTheory/relyra/commit/502417f7b4811ad71aa5bbd29522c55a005cf67c))
* **29-05:** rewire metadata pre-parse onto tree builder + prove SIGV-04 ([6d4931e](https://github.com/szTheory/relyra/commit/6d4931eba1d925b2f1ecea2d99dc101e75b4dcaa))
* **30-01:** delegate FakeIdP.sign to genuine signer + expose trust cert (D-01/D-03) ([18f5bd8](https://github.com/szTheory/relyra/commit/18f5bd8d2c95ea68142b9929a8cf06daec31c29d))
* **30-03:** add c14n-differential rejection row to security corpus ([c7ec6a2](https://github.com/szTheory/relyra/commit/c7ec6a261f4297fe59930d9a7aaaa11adc612a6b))


### Bug Fixes

* **28-03:** correct prot-unsigned-001 expectation to missing_protocol_field ([63c5ca5](https://github.com/szTheory/relyra/commit/63c5ca5ad0b6513ec5b3f88c7beffb8f734ddafc))
* **29-01:** walk content in document order in C14N.render_element/3 (D-09) ([8052658](https://github.com/szTheory/relyra/commit/8052658e07933e2a322393afb1a8c9bf267c78b7))
* **29:** close metadata trust bypass (CR-01) and pin over DER (CR-02) ([8910200](https://github.com/szTheory/relyra/commit/8910200edc77a502d4cbce7ec88188b4bd636f99))
* **29:** thread cert_chain in plan 03 + add existing-test triage task to plan 04 ([13094ef](https://github.com/szTheory/relyra/commit/13094ef1232fcd2fdaedccf942d99788840b3516))
* **29:** tolerate line-wrapped base64 in Signature/DigestValue (WR-01) ([ef44482](https://github.com/szTheory/relyra/commit/ef444820bf09d994547ae7fef6692eccba722916))
* **30-01:** reconcile FakeIdP response_xml shape for genuine signing (D-02) ([f9047fe](https://github.com/szTheory/relyra/commit/f9047fe77145a4039c69b693863dd5c5da868ab1))
* **30-04:** make ci.security honestly gate every security suite (cmd mix test per line) ([8a144ed](https://github.com/szTheory/relyra/commit/8a144ed23a50036a05e124cd4311afd6b8450ac8))
* **30:** harden ci.security meta-gate (AST parse, tag anchor, corpus_gate coverage) ([07f4727](https://github.com/szTheory/relyra/commit/07f4727967b2183637b35b4481167d703b7ec5bd))
* **deps:** bump postgrex/plug/phoenix for CVEs; ignore unreachable decimal advisory ([520d713](https://github.com/szTheory/relyra/commit/520d713f8b124b6029a297c814ed0ba7d365cffb))

## [1.1.0](https://github.com/szTheory/relyra/compare/v1.0.0...v1.1.0) (2026-05-08)


### Features

* **01-02:** add pure-beam XML adapter baseline ([68f1041](https://github.com/szTheory/relyra/commit/68f10410571ab85683b98f92f587023c20527c81))
* **01-02:** add stable Relyra.Error contract ([5077f9d](https://github.com/szTheory/relyra/commit/5077f9d5c821f632fb5dbc68c4f319503d13e103))
* **01-02:** freeze hardened XML seam behaviour ([ed7257e](https://github.com/szTheory/relyra/commit/ed7257ef348c6971f2f1aed424492201bbc1e3c9))
* **01-03:** add compile-time parser path guard ([74bac6e](https://github.com/szTheory/relyra/commit/74bac6ea6f1cdd4d327bfc6e526c7b7627956c4a))
* **02-01:** add protocol and relay state contract tests ([9225186](https://github.com/szTheory/relyra/commit/92251860354e774af875f8f73ac6deb7a3081bb4))
* **02-01:** enforce opaque relay state contract ([d21697f](https://github.com/szTheory/relyra/commit/d21697ff62509c8332c7895dd17dd3bbc8842f0c))
* **02-01:** implement login request and binding primitives ([b0d49b6](https://github.com/szTheory/relyra/commit/b0d49b62eec3354619e5b9a97476407d672f4803))
* **02-02:** bind signature verification to exact signed node ([2aeba97](https://github.com/szTheory/relyra/commit/2aeba972d43391175a94c7793b63c6a5709abc48))
* **02-02:** enforce strict signature algorithm policy ([88d43db](https://github.com/szTheory/relyra/commit/88d43db06a3cd8e4698308c22a751eaf59ceb47a))
* **02-03:** add ordered consume response pipeline ([d7db968](https://github.com/szTheory/relyra/commit/d7db96837f63539bc8a52ac4bdc7cfb5b460cee5))
* **02-03:** add response and assertion validators ([47981a2](https://github.com/szTheory/relyra/commit/47981a28af7ae1c52e43de68956494f5529d9e52))
* **03-01:** add fail-closed default adapter scaffolding ([f4acf93](https://github.com/szTheory/relyra/commit/f4acf932704ff6457defbe704fc36a9037448ef7))
* **03-01:** freeze phase 3 behaviour contracts ([9841e09](https://github.com/szTheory/relyra/commit/9841e09257e052094ece31015781b32c2c07ad5d))
* **03-02:** add atomic ETS request and replay adapters ([223cb72](https://github.com/szTheory/relyra/commit/223cb726d147a031d4da2339c2e097e4045087ad))
* **03-02:** add optional Ecto-backed request and replay stores ([4a801f9](https://github.com/szTheory/relyra/commit/4a801f9c9b9002b2482c7972125c9972c8094e26))
* **03-03:** persist request intent and gate consume success ([a6cf9aa](https://github.com/szTheory/relyra/commit/a6cf9aad4452392714b500683ccdedfe3a936110))
* **05-01:** add telemetry catalog and event spans ([07b503f](https://github.com/szTheory/relyra/commit/07b503f697de2aa91dfc3aa25740f0c3a1527574))
* **06-01:** add provider presets, TestSupport, installer, and docs ([670ee92](https://github.com/szTheory/relyra/commit/670ee926b6ec017ae31bf7af234187f1990734a7))
* **06-01:** close release-discipline gap and add provider audience hint ([bdb7c9a](https://github.com/szTheory/relyra/commit/bdb7c9a8f6c5a3eb7e2e20a535419ed9228daccc))
* **11-02:** add mapping persistence migration coverage ([06856c6](https://github.com/szTheory/relyra/commit/06856c66295121a75ab1cda3ab1893c0a0ee3376))
* **11-03:** harden audited trust mutations ([c546b6b](https://github.com/szTheory/relyra/commit/c546b6b8d501ca7f9e9c0d903e8b93f0345ad724))
* **11-04:** persist and hydrate mapping config ([dd9da43](https://github.com/szTheory/relyra/commit/dd9da43e009b7bc1447ae0f994ee3bb43ec03ec4))
* **12-12-01:** canonicalize metadata certificate candidates ([6d5d652](https://github.com/szTheory/relyra/commit/6d5d65235b2adf4c24fe8b42cb5e42dc72e0e5b4))
* **14-01:** author 11-VERIFICATION.md with serial CFG-05 packet ([4339dca](https://github.com/szTheory/relyra/commit/4339dcae87ba29f995f6635b3546b006fb19eab4))
* **15-01:** create connection list, detail components and normalize risk flag names ([0bdf7b1](https://github.com/szTheory/relyra/commit/0bdf7b1c7d46bdad7e56b11ffa4dabc87ef90ea2))
* **15-02:** extract connection form and preset picker components ([e133380](https://github.com/szTheory/relyra/commit/e133380c72d11694d3291acacb308a3eb3242d79))
* **15-02:** wire URL-driven presets to the form ([50640b8](https://github.com/szTheory/relyra/commit/50640b8c286bdc983caf41ec7143f86e96c1e775))
* **15-03:** embed risk panel across relevant views ([4916649](https://github.com/szTheory/relyra/commit/4916649b8a58718d8ca18419930e5ce5b78e886d))
* **15-03:** wire lifecycle events to Ecto boundaries and add status badges ([0a16b0a](https://github.com/szTheory/relyra/commit/0a16b0a0c36b0abffd3635b21838afe569bcebae))
* **16-01:** establish metadata liveview skeleton and route (and missing 15-01 files) ([c52a008](https://github.com/szTheory/relyra/commit/c52a00895a66c2742a368cad9474064caee57c06))
* **16-02:** add active highlighting to metadata history stream ([8ee6076](https://github.com/szTheory/relyra/commit/8ee60768187ecf0f9490a5893e0c86920a19f8f5))
* **16-03:** finalize Phase 16 execution and verification ([43ce682](https://github.com/szTheory/relyra/commit/43ce682265a447e3b36470e2104617cae4350598))
* **16-03:** implement async manual metadata refresh ([50a0ebd](https://github.com/szTheory/relyra/commit/50a0ebd49ab83131538f8cbea4576387aed29784))
* **17-01:** handle optimistic locking conflicts on certificate updates ([8400944](https://github.com/szTheory/relyra/commit/840094414900683b8bc4fcd8b999ea76ed316e04))
* **17-01:** implement semantic slot-based timeline UI for certificates ([cf7f016](https://github.com/szTheory/relyra/commit/cf7f0169449c04e4074563a6f8b7605356ccd373))
* **17-02:** implement 3-step staged rollover with typed verification ([0399604](https://github.com/szTheory/relyra/commit/03996043bfc780386e592d4f7d73f4c7ef3e969e))
* **18-01:** implement typed mapping forms in live admin ([15bb5f4](https://github.com/szTheory/relyra/commit/15bb5f4e8b415fd111392bd79ae764672b6a3b3c))
* **18-02:** implement audit timeline filtering and expandable details ([7ced8fc](https://github.com/szTheory/relyra/commit/7ced8fc9d8841da56f05f5871d92e31bc836b562))
* **19-01:** implement allow_idp_initiated flag for connections ([26e822c](https://github.com/szTheory/relyra/commit/26e822c66866cd357630eeb208afd97c7b5853cb))
* **19-02:** implement safe local redirect utility ([4fab9cf](https://github.com/szTheory/relyra/commit/4fab9cf7d7dbefeb4fc1d4fe1e7ff62938090388))
* **19:** implement IdP-initiated SSO support and result normalization ([101e2a6](https://github.com/szTheory/relyra/commit/101e2a6bd1cf3ebe548bbaf5f7a1e4f015b6ea83))
* **20-01:** implement BulkActions coordinator ([69be2d9](https://github.com/szTheory/relyra/commit/69be2d95556f53247d4789dee57ba2608b360e0b))
* **20-02:** add multi-select UI to ConnectionList ([4c3bf15](https://github.com/szTheory/relyra/commit/4c3bf1513ec47e96526168d2d8c722b3a1db9e14))
* **20:** implement bulk operations for connections and UI multi-selection ([6e75525](https://github.com/szTheory/relyra/commit/6e75525518ad5e3b0e8851328b537d52b7860a59))
* **21-01:** add migration extending relyra_metadata_sources with auto-refresh ([7dcf2ea](https://github.com/szTheory/relyra/commit/7dcf2eaddbbe54cb10033a37ae2ac2fa2f257eab))
* **21-01:** extend MetadataSource schema with auto-refresh fields and changesets ([d8eb04b](https://github.com/szTheory/relyra/commit/d8eb04b96835dc357f9c9a350936fc16e4c6c4dc))
* **21-02:** pure cadence + backoff helpers with property-style jitter envelopes ([7cfbf02](https://github.com/szTheory/relyra/commit/7cfbf02f33b89a1aeadc9b19e93ada8b656d96bd))
* **21-02:** pure failure classifier with one clause per Phase-21 error code ([f8620bf](https://github.com/szTheory/relyra/commit/f8620bf1839b2a5ffe11656bf57bc2e7d2382ea9))
* **21-03:** add TrustAnchor + DriftDetector pure helpers ([1c02e38](https://github.com/szTheory/relyra/commit/1c02e382a88a635b2526ba28c8e5062e49f96c00))
* **21-03:** relocate security corpus + add CorpusGate runtime gate ([9400a0d](https://github.com/szTheory/relyra/commit/9400a0d22b30807cf83c93f30897acb32ce8999f))
* **21-04:** add MetadataApply.resume_auto_refresh/3 single-tx Resume seam ([b94ce16](https://github.com/szTheory/relyra/commit/b94ce16cfa8ea2fec19b4352c0ec5cae05be3847))
* **21-04:** add Signature.verify_metadata_root/4 metadata-root shim ([35a3da4](https://github.com/szTheory/relyra/commit/35a3da421d8f2bc1ed46dec8308bedd540d03a85))
* **21-04:** wrap record_attempt in transact and co-commit health state ([2de8899](https://github.com/szTheory/relyra/commit/2de8899d1978e0fc56d72b26ae4a806179b1742e))
* **21-05:** add OptionalDeps.Oban gateway and Workers.MetadataRefresh ([ff88242](https://github.com/szTheory/relyra/commit/ff8824243ecaa2a897e71a8f84dc1f2965b285ff))
* **21-05:** add Scheduler.run_due/2 and AutoRefresh.refresh/2 wrapper ([3b60a04](https://github.com/szTheory/relyra/commit/3b60a04fe9a1130279c487f4a3c320ccb31ecd62))
* **21-06:** add Auto-refresh health card + Resume now to ConnectionMetadataLive ([35a4cc7](https://github.com/szTheory/relyra/commit/35a4cc7fa5e2e849090b0bb6432b0fab4bc5d2d0))
* **21-06:** surface auto_refresh_health on the connection list (D-29) ([67da767](https://github.com/szTheory/relyra/commit/67da7679283fe0bf0c37541ee0bd8d1e3b6a35de))
* **21-07:** add Metadata.pin_trust_fingerprint/3 + two operator Mix tasks ([aa25260](https://github.com/szTheory/relyra/commit/aa252604bfc77e8ed01e8c03c50af89823f19164))
* **21-07:** add optional Oban dep, ci.oban_smoke alias, README operations ([f4bf983](https://github.com/szTheory/relyra/commit/f4bf983274dad37d3d08077cd95bcb7f837955fe))
* **21-07:** document auto_refresh telemetry catalog + LogAlerts handler ([06ca068](https://github.com/szTheory/relyra/commit/06ca0682e206db1128eba971153928ce01807ad1))
* **21.1-01:** forward audit context from Refresh.refresh/2 into apply_revision and record_attempt (closes CFG-07) ([80d9001](https://github.com/szTheory/relyra/commit/80d90015568de164db3e67f49299abd646093f6a))
* **22-01:** implement certificate expiry traversal engine ([13bf7f8](https://github.com/szTheory/relyra/commit/13bf7f89d819be8c03f1f02099b92c7fb1d04fd4))
* **22-01:** implement telemetry for expiring certificates ([eef99d4](https://github.com/szTheory/relyra/commit/eef99d4cc99437d09b5ab57add8cbbecc3f6bdae))
* **23-01:** build diagnostic bundle orchestration service ([9b4250c](https://github.com/szTheory/relyra/commit/9b4250c66f59cc3caf29c8bdd50cd3f4a29c8583))
* **23-01:** implement explicit redaction AllowList for diagnostic exports ([74a6efb](https://github.com/szTheory/relyra/commit/74a6efb4c30d6e8cd08c640fd59655efdc43d632))
* **23-02:** add download diagnostic bundle UI button to admin UI ([fe394bf](https://github.com/szTheory/relyra/commit/fe394bf34c3ccff42d191aa899d901b80ea3a0c1))
* **23-02:** create mix task for CLI diagnostic bundle export ([1f074ba](https://github.com/szTheory/relyra/commit/1f074baa58580c47652392720fe8fd70b2c90286))
* **23-02:** implement HTTP download endpoint for diagnostic bundle ([7ce0184](https://github.com/szTheory/relyra/commit/7ce0184862eec9abd79fe12bae4cf7539c6cad8c))
* **24-01:** implement request store type injection ([aff2a30](https://github.com/szTheory/relyra/commit/aff2a30410af444a377acfe95cd5583eb4732573))
* **24-01:** implement session revocation adapter support ([f425c18](https://github.com/szTheory/relyra/commit/f425c1886d19ec03c607b4355c93ed49ba8e1aae))
* **24-02:** implement LogoutRequest builder ([9bfd22c](https://github.com/szTheory/relyra/commit/9bfd22c68868374e178432966762dccf0fb9ae2f))
* **24-03:** implement logout bindings parser for redirect ([d4654ee](https://github.com/szTheory/relyra/commit/d4654ee1861cc1d31df788d6c55a95d33da67486))
* **25-01:** add shared conformance fixture loader ([1f98ee5](https://github.com/szTheory/relyra/commit/1f98ee5393ce56f4f792069ae2b05f04e779dc79))
* **25-01:** harden PureBeam seam behavior ([e8cfab9](https://github.com/szTheory/relyra/commit/e8cfab925f490227469de633565e3310431e0df6))
* **25-02:** expand pinned security regression corpus ([c80b6ab](https://github.com/szTheory/relyra/commit/c80b6abad012ce0380ed349925cee1703734c3cb))
* **25-02:** implement SP conformance lane ([9c3e79a](https://github.com/szTheory/relyra/commit/9c3e79a7e8aa0e14b05506a4fb1ed9dcfccd9360))
* **25-03:** generate conformance report from manifest state ([a9a7d58](https://github.com/szTheory/relyra/commit/a9a7d58ba50ad43b06ccd90dd3e88b5f55ee5a2d))
* **27-03:** add batteries included proof artifact ([0b1ffc9](https://github.com/szTheory/relyra/commit/0b1ffc9ee310762c8023283d6c67f16290fe5b78))


### Bug Fixes

* **01-03:** stabilize security aliases and verification lanes ([e850c7f](https://github.com/szTheory/relyra/commit/e850c7f519ae34e7e7d6322e30f86e157093c8a0))
* **02-01:** align request primitives with verification gate checks ([1938caf](https://github.com/szTheory/relyra/commit/1938caf14dca222946310c98cb2fd8a43484eb22))
* **02-02:** format signature policy and binding files ([ff0b471](https://github.com/szTheory/relyra/commit/ff0b47134611c4e7d6f080f97852393358ac06a3))
* **02-03:** format consume pipeline sources ([a07ed0d](https://github.com/szTheory/relyra/commit/a07ed0d2b89f5d246335813e83ad22f7c2ffbbbe))
* **03-01:** format contract defaults for strict verification ([7066eda](https://github.com/szTheory/relyra/commit/7066edaa0d9a8b52ea64f4f94c1c4d5a311f5651))
* **12-12-02:** preserve staged metadata apply semantics ([c5c937e](https://github.com/szTheory/relyra/commit/c5c937e98328aa2d8453cef169216eed99d21742))
* **12-12-02:** repair refresh candidate seam ([206bdd5](https://github.com/szTheory/relyra/commit/206bdd5d37a3a069e69a22831f31d6e4f4874028))
* **21.2:** revise plans based on checker feedback ([5030090](https://github.com/szTheory/relyra/commit/50300902892804667df387ea2ea3a591910beef4))
* **test:** ensure MetadataRefresh is loaded before function_exported? check ([abc24fa](https://github.com/szTheory/relyra/commit/abc24fafaa9513d5aad7404a886bfdcb2a0ec149))

## 1.0.0 (2026-05-08)


### Features

* **01-02:** add pure-beam XML adapter baseline ([68f1041](https://github.com/szTheory/relyra/commit/68f10410571ab85683b98f92f587023c20527c81))
* **01-02:** add stable Relyra.Error contract ([5077f9d](https://github.com/szTheory/relyra/commit/5077f9d5c821f632fb5dbc68c4f319503d13e103))
* **01-02:** freeze hardened XML seam behaviour ([ed7257e](https://github.com/szTheory/relyra/commit/ed7257ef348c6971f2f1aed424492201bbc1e3c9))
* **01-03:** add compile-time parser path guard ([74bac6e](https://github.com/szTheory/relyra/commit/74bac6ea6f1cdd4d327bfc6e526c7b7627956c4a))
* **02-01:** add protocol and relay state contract tests ([9225186](https://github.com/szTheory/relyra/commit/92251860354e774af875f8f73ac6deb7a3081bb4))
* **02-01:** enforce opaque relay state contract ([d21697f](https://github.com/szTheory/relyra/commit/d21697ff62509c8332c7895dd17dd3bbc8842f0c))
* **02-01:** implement login request and binding primitives ([b0d49b6](https://github.com/szTheory/relyra/commit/b0d49b62eec3354619e5b9a97476407d672f4803))
* **02-02:** bind signature verification to exact signed node ([2aeba97](https://github.com/szTheory/relyra/commit/2aeba972d43391175a94c7793b63c6a5709abc48))
* **02-02:** enforce strict signature algorithm policy ([88d43db](https://github.com/szTheory/relyra/commit/88d43db06a3cd8e4698308c22a751eaf59ceb47a))
* **02-03:** add ordered consume response pipeline ([d7db968](https://github.com/szTheory/relyra/commit/d7db96837f63539bc8a52ac4bdc7cfb5b460cee5))
* **02-03:** add response and assertion validators ([47981a2](https://github.com/szTheory/relyra/commit/47981a28af7ae1c52e43de68956494f5529d9e52))
* **03-01:** add fail-closed default adapter scaffolding ([f4acf93](https://github.com/szTheory/relyra/commit/f4acf932704ff6457defbe704fc36a9037448ef7))
* **03-01:** freeze phase 3 behaviour contracts ([9841e09](https://github.com/szTheory/relyra/commit/9841e09257e052094ece31015781b32c2c07ad5d))
* **03-02:** add atomic ETS request and replay adapters ([223cb72](https://github.com/szTheory/relyra/commit/223cb726d147a031d4da2339c2e097e4045087ad))
* **03-02:** add optional Ecto-backed request and replay stores ([4a801f9](https://github.com/szTheory/relyra/commit/4a801f9c9b9002b2482c7972125c9972c8094e26))
* **03-03:** persist request intent and gate consume success ([a6cf9aa](https://github.com/szTheory/relyra/commit/a6cf9aad4452392714b500683ccdedfe3a936110))
* **05-01:** add telemetry catalog and event spans ([07b503f](https://github.com/szTheory/relyra/commit/07b503f697de2aa91dfc3aa25740f0c3a1527574))
* **06-01:** add provider presets, TestSupport, installer, and docs ([670ee92](https://github.com/szTheory/relyra/commit/670ee926b6ec017ae31bf7af234187f1990734a7))
* **06-01:** close release-discipline gap and add provider audience hint ([bdb7c9a](https://github.com/szTheory/relyra/commit/bdb7c9a8f6c5a3eb7e2e20a535419ed9228daccc))
* **11-02:** add mapping persistence migration coverage ([06856c6](https://github.com/szTheory/relyra/commit/06856c66295121a75ab1cda3ab1893c0a0ee3376))
* **11-03:** harden audited trust mutations ([c546b6b](https://github.com/szTheory/relyra/commit/c546b6b8d501ca7f9e9c0d903e8b93f0345ad724))
* **11-04:** persist and hydrate mapping config ([dd9da43](https://github.com/szTheory/relyra/commit/dd9da43e009b7bc1447ae0f994ee3bb43ec03ec4))
* **12-12-01:** canonicalize metadata certificate candidates ([6d5d652](https://github.com/szTheory/relyra/commit/6d5d65235b2adf4c24fe8b42cb5e42dc72e0e5b4))
* **14-01:** author 11-VERIFICATION.md with serial CFG-05 packet ([4339dca](https://github.com/szTheory/relyra/commit/4339dcae87ba29f995f6635b3546b006fb19eab4))
* **15-01:** create connection list, detail components and normalize risk flag names ([0bdf7b1](https://github.com/szTheory/relyra/commit/0bdf7b1c7d46bdad7e56b11ffa4dabc87ef90ea2))
* **15-02:** extract connection form and preset picker components ([e133380](https://github.com/szTheory/relyra/commit/e133380c72d11694d3291acacb308a3eb3242d79))
* **15-02:** wire URL-driven presets to the form ([50640b8](https://github.com/szTheory/relyra/commit/50640b8c286bdc983caf41ec7143f86e96c1e775))
* **15-03:** embed risk panel across relevant views ([4916649](https://github.com/szTheory/relyra/commit/4916649b8a58718d8ca18419930e5ce5b78e886d))
* **15-03:** wire lifecycle events to Ecto boundaries and add status badges ([0a16b0a](https://github.com/szTheory/relyra/commit/0a16b0a0c36b0abffd3635b21838afe569bcebae))
* **16-01:** establish metadata liveview skeleton and route (and missing 15-01 files) ([c52a008](https://github.com/szTheory/relyra/commit/c52a00895a66c2742a368cad9474064caee57c06))
* **16-02:** add active highlighting to metadata history stream ([8ee6076](https://github.com/szTheory/relyra/commit/8ee60768187ecf0f9490a5893e0c86920a19f8f5))
* **16-03:** finalize Phase 16 execution and verification ([43ce682](https://github.com/szTheory/relyra/commit/43ce682265a447e3b36470e2104617cae4350598))
* **16-03:** implement async manual metadata refresh ([50a0ebd](https://github.com/szTheory/relyra/commit/50a0ebd49ab83131538f8cbea4576387aed29784))
* **17-01:** handle optimistic locking conflicts on certificate updates ([8400944](https://github.com/szTheory/relyra/commit/840094414900683b8bc4fcd8b999ea76ed316e04))
* **17-01:** implement semantic slot-based timeline UI for certificates ([cf7f016](https://github.com/szTheory/relyra/commit/cf7f0169449c04e4074563a6f8b7605356ccd373))
* **17-02:** implement 3-step staged rollover with typed verification ([0399604](https://github.com/szTheory/relyra/commit/03996043bfc780386e592d4f7d73f4c7ef3e969e))
* **18-01:** implement typed mapping forms in live admin ([15bb5f4](https://github.com/szTheory/relyra/commit/15bb5f4e8b415fd111392bd79ae764672b6a3b3c))
* **18-02:** implement audit timeline filtering and expandable details ([7ced8fc](https://github.com/szTheory/relyra/commit/7ced8fc9d8841da56f05f5871d92e31bc836b562))
* **19-01:** implement allow_idp_initiated flag for connections ([26e822c](https://github.com/szTheory/relyra/commit/26e822c66866cd357630eeb208afd97c7b5853cb))
* **19-02:** implement safe local redirect utility ([4fab9cf](https://github.com/szTheory/relyra/commit/4fab9cf7d7dbefeb4fc1d4fe1e7ff62938090388))
* **19:** implement IdP-initiated SSO support and result normalization ([101e2a6](https://github.com/szTheory/relyra/commit/101e2a6bd1cf3ebe548bbaf5f7a1e4f015b6ea83))
* **20-01:** implement BulkActions coordinator ([69be2d9](https://github.com/szTheory/relyra/commit/69be2d95556f53247d4789dee57ba2608b360e0b))
* **20-02:** add multi-select UI to ConnectionList ([4c3bf15](https://github.com/szTheory/relyra/commit/4c3bf1513ec47e96526168d2d8c722b3a1db9e14))
* **20:** implement bulk operations for connections and UI multi-selection ([6e75525](https://github.com/szTheory/relyra/commit/6e75525518ad5e3b0e8851328b537d52b7860a59))
* **21-01:** add migration extending relyra_metadata_sources with auto-refresh ([7dcf2ea](https://github.com/szTheory/relyra/commit/7dcf2eaddbbe54cb10033a37ae2ac2fa2f257eab))
* **21-01:** extend MetadataSource schema with auto-refresh fields and changesets ([d8eb04b](https://github.com/szTheory/relyra/commit/d8eb04b96835dc357f9c9a350936fc16e4c6c4dc))
* **21-02:** pure cadence + backoff helpers with property-style jitter envelopes ([7cfbf02](https://github.com/szTheory/relyra/commit/7cfbf02f33b89a1aeadc9b19e93ada8b656d96bd))
* **21-02:** pure failure classifier with one clause per Phase-21 error code ([f8620bf](https://github.com/szTheory/relyra/commit/f8620bf1839b2a5ffe11656bf57bc2e7d2382ea9))
* **21-03:** add TrustAnchor + DriftDetector pure helpers ([1c02e38](https://github.com/szTheory/relyra/commit/1c02e382a88a635b2526ba28c8e5062e49f96c00))
* **21-03:** relocate security corpus + add CorpusGate runtime gate ([9400a0d](https://github.com/szTheory/relyra/commit/9400a0d22b30807cf83c93f30897acb32ce8999f))
* **21-04:** add MetadataApply.resume_auto_refresh/3 single-tx Resume seam ([b94ce16](https://github.com/szTheory/relyra/commit/b94ce16cfa8ea2fec19b4352c0ec5cae05be3847))
* **21-04:** add Signature.verify_metadata_root/4 metadata-root shim ([35a3da4](https://github.com/szTheory/relyra/commit/35a3da421d8f2bc1ed46dec8308bedd540d03a85))
* **21-04:** wrap record_attempt in transact and co-commit health state ([2de8899](https://github.com/szTheory/relyra/commit/2de8899d1978e0fc56d72b26ae4a806179b1742e))
* **21-05:** add OptionalDeps.Oban gateway and Workers.MetadataRefresh ([ff88242](https://github.com/szTheory/relyra/commit/ff8824243ecaa2a897e71a8f84dc1f2965b285ff))
* **21-05:** add Scheduler.run_due/2 and AutoRefresh.refresh/2 wrapper ([3b60a04](https://github.com/szTheory/relyra/commit/3b60a04fe9a1130279c487f4a3c320ccb31ecd62))
* **21-06:** add Auto-refresh health card + Resume now to ConnectionMetadataLive ([35a4cc7](https://github.com/szTheory/relyra/commit/35a4cc7fa5e2e849090b0bb6432b0fab4bc5d2d0))
* **21-06:** surface auto_refresh_health on the connection list (D-29) ([67da767](https://github.com/szTheory/relyra/commit/67da7679283fe0bf0c37541ee0bd8d1e3b6a35de))
* **21-07:** add Metadata.pin_trust_fingerprint/3 + two operator Mix tasks ([aa25260](https://github.com/szTheory/relyra/commit/aa252604bfc77e8ed01e8c03c50af89823f19164))
* **21-07:** add optional Oban dep, ci.oban_smoke alias, README operations ([f4bf983](https://github.com/szTheory/relyra/commit/f4bf983274dad37d3d08077cd95bcb7f837955fe))
* **21-07:** document auto_refresh telemetry catalog + LogAlerts handler ([06ca068](https://github.com/szTheory/relyra/commit/06ca0682e206db1128eba971153928ce01807ad1))
* **21.1-01:** forward audit context from Refresh.refresh/2 into apply_revision and record_attempt (closes CFG-07) ([80d9001](https://github.com/szTheory/relyra/commit/80d90015568de164db3e67f49299abd646093f6a))
* **22-01:** implement certificate expiry traversal engine ([13bf7f8](https://github.com/szTheory/relyra/commit/13bf7f89d819be8c03f1f02099b92c7fb1d04fd4))
* **22-01:** implement telemetry for expiring certificates ([eef99d4](https://github.com/szTheory/relyra/commit/eef99d4cc99437d09b5ab57add8cbbecc3f6bdae))
* **23-01:** build diagnostic bundle orchestration service ([9b4250c](https://github.com/szTheory/relyra/commit/9b4250c66f59cc3caf29c8bdd50cd3f4a29c8583))
* **23-01:** implement explicit redaction AllowList for diagnostic exports ([74a6efb](https://github.com/szTheory/relyra/commit/74a6efb4c30d6e8cd08c640fd59655efdc43d632))
* **23-02:** add download diagnostic bundle UI button to admin UI ([fe394bf](https://github.com/szTheory/relyra/commit/fe394bf34c3ccff42d191aa899d901b80ea3a0c1))
* **23-02:** create mix task for CLI diagnostic bundle export ([1f074ba](https://github.com/szTheory/relyra/commit/1f074baa58580c47652392720fe8fd70b2c90286))
* **23-02:** implement HTTP download endpoint for diagnostic bundle ([7ce0184](https://github.com/szTheory/relyra/commit/7ce0184862eec9abd79fe12bae4cf7539c6cad8c))
* **24-01:** implement request store type injection ([aff2a30](https://github.com/szTheory/relyra/commit/aff2a30410af444a377acfe95cd5583eb4732573))
* **24-01:** implement session revocation adapter support ([f425c18](https://github.com/szTheory/relyra/commit/f425c1886d19ec03c607b4355c93ed49ba8e1aae))
* **24-02:** implement LogoutRequest builder ([9bfd22c](https://github.com/szTheory/relyra/commit/9bfd22c68868374e178432966762dccf0fb9ae2f))
* **24-03:** implement logout bindings parser for redirect ([d4654ee](https://github.com/szTheory/relyra/commit/d4654ee1861cc1d31df788d6c55a95d33da67486))
* **25-01:** add shared conformance fixture loader ([1f98ee5](https://github.com/szTheory/relyra/commit/1f98ee5393ce56f4f792069ae2b05f04e779dc79))
* **25-01:** harden PureBeam seam behavior ([e8cfab9](https://github.com/szTheory/relyra/commit/e8cfab925f490227469de633565e3310431e0df6))
* **25-02:** expand pinned security regression corpus ([c80b6ab](https://github.com/szTheory/relyra/commit/c80b6abad012ce0380ed349925cee1703734c3cb))
* **25-02:** implement SP conformance lane ([9c3e79a](https://github.com/szTheory/relyra/commit/9c3e79a7e8aa0e14b05506a4fb1ed9dcfccd9360))
* **25-03:** generate conformance report from manifest state ([a9a7d58](https://github.com/szTheory/relyra/commit/a9a7d58ba50ad43b06ccd90dd3e88b5f55ee5a2d))
* **27-03:** add batteries included proof artifact ([0b1ffc9](https://github.com/szTheory/relyra/commit/0b1ffc9ee310762c8023283d6c67f16290fe5b78))


### Bug Fixes

* **01-03:** stabilize security aliases and verification lanes ([e850c7f](https://github.com/szTheory/relyra/commit/e850c7f519ae34e7e7d6322e30f86e157093c8a0))
* **02-01:** align request primitives with verification gate checks ([1938caf](https://github.com/szTheory/relyra/commit/1938caf14dca222946310c98cb2fd8a43484eb22))
* **02-02:** format signature policy and binding files ([ff0b471](https://github.com/szTheory/relyra/commit/ff0b47134611c4e7d6f080f97852393358ac06a3))
* **02-03:** format consume pipeline sources ([a07ed0d](https://github.com/szTheory/relyra/commit/a07ed0d2b89f5d246335813e83ad22f7c2ffbbbe))
* **03-01:** format contract defaults for strict verification ([7066eda](https://github.com/szTheory/relyra/commit/7066edaa0d9a8b52ea64f4f94c1c4d5a311f5651))
* **12-12-02:** preserve staged metadata apply semantics ([c5c937e](https://github.com/szTheory/relyra/commit/c5c937e98328aa2d8453cef169216eed99d21742))
* **12-12-02:** repair refresh candidate seam ([206bdd5](https://github.com/szTheory/relyra/commit/206bdd5d37a3a069e69a22831f31d6e4f4874028))
* **21.2:** revise plans based on checker feedback ([5030090](https://github.com/szTheory/relyra/commit/50300902892804667df387ea2ea3a591910beef4))
* **test:** ensure MetadataRefresh is loaded before function_exported? check ([abc24fa](https://github.com/szTheory/relyra/commit/abc24fafaa9513d5aad7404a886bfdcb2a0ec149))

## [Unreleased]

## [0.1.0] - 2026-05-08

### Added

- Initial public release of the strict-by-default SAML 2.0 SP surface.
- Provider presets for Okta, Entra, and Google Workspace.
- `Relyra.TestSupport`, `Relyra.TestSupport.FakeIdP`, and installer scaffolding.
- Release hardening metadata, parity checks, and release-time prerequisite guidance.
