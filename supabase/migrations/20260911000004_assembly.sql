-- Palabre — assemblée : législatures, circonscriptions, suppléance, activité
--
-- Pas de scrutins nominatifs dans cette version (section 7). Le booléen
-- legislature.scrutins_nominatifs pilote le bandeau « indisponibles ».

create table public.legislature (
  id                   bigserial primary key,
  country_code         text not null references public.country(code),
  numero               int not null,
  debut                date not null,
  fin                  date,
  sieges_total         int not null check (sieges_total > 0),
  scrutins_nominatifs  boolean not null default false,
  source_url           text,
  unique (country_code, numero),
  check (fin is null or fin > debut)
);

create table public.constituency (
  id             bigserial primary key,
  country_code   text not null references public.country(code),
  legislature_id bigint not null references public.legislature(id),
  nom            text not null,
  type           text not null check (type in ('departement', 'region', 'liste_nationale', 'diaspora')),
  sieges         int not null check (sieges > 0),
  region_id      bigint,          -- permet le filtre « par région »
  unique (legislature_id, nom),
  foreign key (region_id, country_code) references public.region(id, country_code)
);

alter table public.mandate
  add constraint mandate_constituency_fk
    foreign key (constituency_id) references public.constituency(id),
  add column qualite text not null default 'titulaire' check (qualite in ('titulaire', 'suppleant')),
  add column remplace_mandate_id bigint references public.mandate(id),
  add constraint mandate_suppleant_remplace
    check (qualite = 'titulaire' or remplace_mandate_id is not null);

comment on column public.mandate.qualite is
  'Un titulaire nommé ministre est remplacé par son suppléant : le mandat du titulaire se clôt (motif nomination_gouvernement), celui du suppléant s''ouvre en pointant sur lui.';

create index mandate_constituency_idx on public.mandate (constituency_id);

-- Indicateurs d'activité : uniquement ce qui est réellement publié.
-- Aucun score, aucun classement, aucune note.
create table public.deputy_activity (
  id                bigserial primary key,
  mandate_id        bigint not null references public.mandate(id) on delete cascade,
  periode           text not null,                -- ex. « session 2025-2026 »
  seances_presentes int check (seances_presentes >= 0),
  seances_total     int check (seances_total >= 0),
  questions_ecrites int check (questions_ecrites >= 0),
  questions_orales  int check (questions_orales >= 0),
  propositions      int check (propositions >= 0),
  commissions       int check (commissions >= 0),
  source_url        text not null,
  maj               date not null default current_date,
  unique (mandate_id, periode),
  check (seances_presentes is null or seances_total is null or seances_presentes <= seances_total)
);
comment on table public.deputy_activity is
  'Chaque colonne est nulle quand l''assemblée ne publie pas la donnée. Le client affiche alors « non publié », jamais 0.';

-- Composition d'une assemblée à une date donnée (titulaires et suppléants en exercice).
create or replace function public.assemblee_a(p_country text, p_date date)
returns table (
  legislature_id   bigint,
  mandate_id       bigint,
  person_id        bigint,
  person_nom       text,
  photo_url        text,
  constituency_id  bigint,
  constituency_nom text,
  qualite          text,
  groupe_id        bigint,
  groupe_nom       text,
  groupe_couleur   text,
  parti_id         bigint,
  parti_nom        text,
  debut            date,
  fin              date,
  source_url       text,
  confiance        text
)
language sql stable
set search_path = public
as $$
  select l.id, m.id, p.id, p.nom, p.photo_url, c.id, c.nom, m.qualite,
         g.id, g.nom, g.couleur, pa.id, pa.nom,
         m.debut, m.fin, m.source_url, m.confiance
  from legislature l
  join constituency c on c.legislature_id = l.id
  join mandate m on m.constituency_id = c.id
  join role r on r.id = m.role_id and r.type = 'depute'
  join person p on p.id = m.person_id
  left join lateral (
    select o.id, o.nom, o.couleur from affiliation a
    join organization o on o.id = a.organization_id and o.type = 'groupe_parlementaire'
    where a.person_id = p.id and a.debut <= p_date and (a.fin is null or a.fin > p_date)
    order by a.debut desc limit 1
  ) g on true
  left join lateral (
    select o.id, o.nom from affiliation a
    join organization o on o.id = a.organization_id and o.type in ('parti', 'coalition')
    where a.person_id = p.id and a.debut <= p_date and (a.fin is null or a.fin > p_date)
    order by a.debut desc limit 1
  ) pa on true
  where l.country_code = p_country
    and l.debut <= p_date and (l.fin is null or l.fin > p_date)
    and m.debut <= p_date and (m.fin is null or m.fin > p_date)
  order by c.nom, p.nom;
$$;
