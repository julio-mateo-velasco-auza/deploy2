// src/lib/api.ts
export const API_BASE = import.meta.env.PUBLIC_API_BASE as string;
export const BACK_BASE = API_BASE.replace(/\/api$/, "");

async function fetchJSON(path: string, init: RequestInit = {}) {
  const res = await fetch(`${API_BASE}${path}`, {
    credentials: "include",
    headers: { "Content-Type": "application/json", ...(init.headers || {}) },
    ...init,
  });
  const ct = res.headers.get("content-type") || "";
  const isJSON = ct.includes("application/json");
  const data = isJSON ? await res.json() : await res.text();
  if (!res.ok) throw new Error(typeof data === "string" ? data : data?.error || "Request failed");
  return data;
}

export const api = {
  // Health
  health: () => fetchJSON("/health"),

  // Auth
  login: (email: string, password: string) =>
    fetchJSON("/auth/login", { method: "POST", body: JSON.stringify({ email, password }) }),
  logout: () => fetchJSON("/auth/logout", { method: "POST" }),
  me: () => fetchJSON("/auth/me"),

  // QR
  qrCreate: (input: { type: string; payload?: any; expires_at?: string; usage_limit?: number | null }) =>
    fetchJSON("/qr/create", { method: "POST", body: JSON.stringify(input) }),
  qrList: () => fetchJSON("/qr/list"),
  qrRevoke: (code: string) =>
    fetchJSON("/qr/revoke", { method: "POST", body: JSON.stringify({ code }) }),
  qrValidate: (code: string) => fetchJSON(`/qr/validate?code=${encodeURIComponent(code)}`),

  // Landing / acceso
  accessPayload: (token?: string) =>
    fetchJSON(`/access/payload${token ? `?token=${encodeURIComponent(token)}` : ""}`),
};

