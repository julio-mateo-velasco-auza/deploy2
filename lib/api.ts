// src/lib/api.ts
export const API_BASE = import.meta.env.PUBLIC_API_BASE || 'http://localhost/inbolsa-api/api';
export const BACK_BASE = API_BASE.replace(/\/api$/, "");

async function fetchJSON(path: string, init: RequestInit = {}) {
  console.log(`Fetching ${API_BASE}${path}`, init);
  
  try {
    const res = await fetch(`${API_BASE}${path}`, {
      credentials: "include",
      headers: { 
        "Content-Type": "application/json", 
        ...(init.headers || {}) 
      },
      ...init,
    });
    
    const ct = res.headers.get("content-type") || "";
    const isJSON = ct.includes("application/json");
    
    let data;
    let responseText = '';
    
    try {
      responseText = await res.text();
      data = responseText ? JSON.parse(responseText) : {};
    } catch (parseErr) {
      console.error("Error parsing JSON response:", parseErr);
      console.error("Response text:", responseText);
      throw new Error(`Respuesta inválida: ${responseText.substring(0, 100)}`);
    }
    
    if (!res.ok) {
      throw new Error(typeof data === "string" ? data : data?.error || "Request failed");
    }
    
    return data;
  } catch (err) {
    console.error(`Error fetching ${path}:`, err);
    throw err;
  }
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
    fetchJSON("/qr/create", { 
      method: "POST", 
      body: JSON.stringify(input),
      headers: {
        "Content-Type": "application/json"
      }
    }),
  qrList: () => fetchJSON("/qr/list"),
  qrRevoke: (code: string) =>
    fetchJSON("/qr/revoke", { method: "POST", body: JSON.stringify({ code }) }),
  qrValidate: (code: string) => fetchJSON(`/qr/validate?code=${encodeURIComponent(code)}`),

  // Landing / acceso
  accessPayload: (token?: string) =>
    fetchJSON(`/access/payload${token ? `?token=${encodeURIComponent(token)}` : ""}`),
};
