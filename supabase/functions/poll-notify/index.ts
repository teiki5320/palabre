// Palabre — notification hebdomadaire.
//
// Appelée toutes les heures par pg_cron (migration 0009) avec le rôle de
// service. Deux cas, décidés côté base par notification_destinataires() :
//   - "ouverture" : la question du lundi vient d'ouvrir ;
//   - "rappel"    : samedi 10h locale, pour ceux qui n'ont pas voté.
// Rien d'autre. Une app politique qui notifie souvent se fait désinstaller.

import { createClient } from "npm:@supabase/supabase-js@2";
import { loadServiceAccount, sendToToken } from "../_shared/fcm.ts";

type Type = "ouverture" | "rappel";

interface Destinataire {
  token: string;
  langue: string;
  poll_id: number;
  question: string;
  country_code: string;
}

const TEXTES: Record<string, Record<Type, { title: string; body: (q: string) => string }>> = {
  fr: {
    ouverture: { title: "Question de la semaine", body: (q) => q },
    rappel: { title: "Il reste jusqu'à dimanche 20h", body: (q) => `Vous n'avez pas encore répondu : ${q}` },
  },
  en: {
    ouverture: { title: "Question of the week", body: (q) => q },
    rappel: { title: "Open until Sunday 8pm", body: (q) => `You have not answered yet: ${q}` },
  },
  wo: {
    ouverture: { title: "Laaju ayu-bés bi", body: (q) => q },
    rappel: { title: "Ba dibéer 20h", body: (q) => `Tontoo gu ba tey : ${q}` },
  },
};

function texte(langue: string, type: Type, question: string) {
  const t = (TEXTES[langue] ?? TEXTES.fr)[type];
  return { title: t.title, body: t.body(question) };
}

Deno.serve(async (req) => {
  const auth = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!serviceKey || auth !== `Bearer ${serviceKey}`) {
    return new Response("Forbidden", { status: 403 });
  }

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, serviceKey, { auth: { persistSession: false } });
  const body = await req.json().catch(() => ({})) as { types?: Type[] };
  const types: Type[] = body.types ?? ["ouverture", "rappel"];

  let sa;
  try {
    sa = loadServiceAccount();
  } catch (e) {
    return Response.json({ error: String(e) }, { status: 500 });
  }

  const report: Record<string, { envoyes: number; invalides: number; erreurs: number }> = {};
  for (const type of types) {
    const { data, error } = await supabase.rpc("notification_destinataires", { p_type: type });
    if (error) return Response.json({ error: error.message }, { status: 500 });
    const dests = (data ?? []) as Destinataire[];
    const r = { envoyes: 0, invalides: 0, erreurs: 0 };
    const invalid: string[] = [];

    // Envois par lots de 20 pour rester sous les limites de l'Edge Runtime.
    for (let i = 0; i < dests.length; i += 20) {
      const lot = dests.slice(i, i + 20);
      const results = await Promise.all(lot.map((d) =>
        sendToToken(sa, d.token, texte(d.langue, type, d.question), {
          type,
          poll_id: String(d.poll_id),
          country_code: d.country_code,
        })
      ));
      results.forEach((res, k) => {
        if (res === "ok") r.envoyes++;
        else if (res === "invalid_token") {
          r.invalides++;
          invalid.push(lot[k].token);
        } else r.erreurs++;
      });
    }
    if (invalid.length > 0) {
      await supabase.from("device_token").delete().in("token", invalid);
    }
    report[type] = r;
  }
  return Response.json(report);
});
