import { Icon } from "@iconify/react";
import type { FormEvent } from "react";
import type { DailyState } from "../../domain";

export function DailyPanel({
  state,
  history,
  me,
  draft,
  busy,
  setDraft,
  submit,
  refresh,
}: {
  state: DailyState | null;
  history: DailyState[];
  me: number;
  draft: string;
  busy: boolean;
  setDraft: (value: string) => void;
  submit: (event: FormEvent) => void;
  refresh: () => void;
}) {
  const mine = state?.replies?.find((reply) => reply.slot === me);
  const partner = state?.replies?.find((reply) => reply.slot !== me);
  const revealed = Boolean(state?.revealedAt);
  return (
    <main className="daily-page">
      <header className="daily-heading">
        <div>
          <p>TWO LETTERS · ONE MOMENT</p>
          <h1>今天，想更懂你一点。</h1>
          <span>答案会先被好好收着，等两个人都写完再一起打开。</span>
        </div>
        <button type="button" onClick={refresh} title="刷新今日状态">
          <Icon icon="solar:refresh-bold" />
        </button>
      </header>
      {!state
        ? (
          <section className="daily-empty">
            <Icon icon="solar:magic-stick-3-bold-duotone" />
            <strong>今天的问题正在准备中</strong>
            <span>AI 暂时不可用时，也会从温柔题库里选一个问题。</span>
          </section>
        )
        : (
          <>
            <section className={`daily-question-card ${revealed ? "revealed" : ""}`}>
              <div className="daily-question-meta">
                <span>{state.source === "ai" ? "AI DAILY QUESTION" : "CURATED QUESTION"}</span>
                <em>{state.category}</em>
              </div>
              <h2>{state.question}</h2>
              <div className="reply-presence">
                <span className={mine?.submitted ? "done" : ""}>
                  <Icon icon={mine?.submitted ? "solar:check-circle-bold" : "solar:pen-new-square-bold"} />
                  我 · {mine?.submitted ? "已写下" : "还没回答"}
                </span>
                <i />
                <span className={partner?.submitted ? "done" : ""}>
                  <Icon icon={partner?.submitted ? "solar:check-circle-bold" : "solar:letter-unread-bold"} />
                  TA · {partner?.submitted ? "回信已到" : "还在想"}
                </span>
              </div>
            </section>

            {revealed
              ? (
                <section className="revealed-letters" aria-live="polite">
                  {state.replies.map((reply) => (
                    <article className={reply.slot === me ? "mine" : "partner"} key={reply.slot}>
                      <span>{reply.slot === me ? "我的回信" : "TA 的回信"}</span>
                      <p>{reply.content}</p>
                    </article>
                  ))}
                  <div className="reveal-seal">
                    <Icon icon="solar:heart-bold" />
                    两封回信，在这一刻一起打开
                  </div>
                </section>
              )
              : (
                <form className="daily-composer" onSubmit={submit}>
                  <div>
                    <span>{mine?.submitted ? "你的回信已被保管，可以在揭晓前修改" : "写下你的答案"}</span>
                    {partner?.submitted && !mine?.submitted && <em>TA 的回信已经在等你了</em>}
                  </div>
                  <textarea
                    value={draft}
                    maxLength={1000}
                    onChange={(event) => setDraft(event.target.value)}
                    placeholder="不用写得完美，写下此刻真实的想法就好…"
                  />
                  <footer>
                    <small>{draft.length}/1000 · 对方暂时看不到内容</small>
                    <button type="submit" disabled={busy || !draft.trim()}>
                      {busy ? "正在封存…" : mine?.submitted ? "更新回信" : "封存这封回信"}
                      <Icon icon="solar:letter-bold" />
                    </button>
                  </footer>
                </form>
              )}
          </>
        )}

      <section className="daily-history">
        <header>
          <div><p>OUR ANSWER ARCHIVE</p><h2>一起打开过的回信</h2></div>
          <span>{history.length} 个共同瞬间</span>
        </header>
        <div className="daily-history-list">
          {history.length
            ? history.map((item) => (
              <article key={item.ID}>
                <time>{new Date(item.questionDate).toLocaleDateString("zh-CN", { month: "long", day: "numeric" })}</time>
                <h3>{item.question}</h3>
                <div>
                  {item.replies.map((reply) => (
                    <p key={reply.slot}><b>{reply.slot === me ? "我" : "TA"}</b>{reply.content}</p>
                  ))}
                </div>
              </article>
            ))
            : <p className="history-empty">第一份共同答案，会从今天开始留在这里。</p>}
        </div>
      </section>
    </main>
  );
}
