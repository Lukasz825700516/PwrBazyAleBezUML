--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1
-- Dumped by pg_dump version 16.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: konto; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.konto (
    id integer NOT NULL,
    nr numeric(24,0) NOT NULL,
    srodki integer NOT NULL
);


ALTER TABLE public.konto OWNER TO admin;

--
-- Name: lokata; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.lokata (
    lokata integer NOT NULL,
    konto integer NOT NULL,
    srodki integer NOT NULL,
    data date NOT NULL
);


ALTER TABLE public.lokata OWNER TO admin;

--
-- Name: close_lokata(integer, integer); Type: PROCEDURE; Schema: public; Owner: admin
--

CREATE PROCEDURE public.close_lokata(IN p_konto integer, IN p_lokata integer)
    LANGUAGE sql
    BEGIN ATOMIC
 UPDATE public.konto SET srodki = (konto.srodki + ( SELECT lokata.srodki
            FROM public.lokata
           WHERE ((lokata.konto = close_lokata.p_konto) AND (lokata.lokata = close_lokata.p_lokata))))
   WHERE (konto.id = close_lokata.p_konto);
 DELETE FROM public.lokata
   WHERE ((lokata.lokata = close_lokata.p_lokata) AND (lokata.konto = close_lokata.p_konto));
END;


ALTER PROCEDURE public.close_lokata(IN p_konto integer, IN p_lokata integer) OWNER TO admin;

--
-- Name: przelew(numeric, numeric, integer, character varying); Type: PROCEDURE; Schema: public; Owner: admin
--

CREATE PROCEDURE public.przelew(IN p_nadawca numeric, IN p_adresat numeric, IN p_kwota integer, IN p_tytul character varying)
    LANGUAGE plpgsql
    AS $$
begin
 if exists (select 1 from konto where nr=p_nadawca and srodki >= p_kwota)  then
   insert into przelew(nadawca, adresat, kwota, data, tytul) values (p_nadawca, p_adresat, p_kwota, NOW(), p_tytul);
   update konto set srodki=srodki-p_kwota where konto.nr = p_nadawca;
  end if;
end; $$;


ALTER PROCEDURE public.przelew(IN p_nadawca numeric, IN p_adresat numeric, IN p_kwota integer, IN p_tytul character varying) OWNER TO admin;

--
-- Name: run_reccurent_payments(); Type: PROCEDURE; Schema: public; Owner: admin
--

CREATE PROCEDURE public.run_reccurent_payments()
    LANGUAGE plpgsql
    AS $$ 
 declare my_cur cursor for 
select
nadawca,
adresat,
kwota,
tytul,
extract(epoch from data),
extract(epoch from faza),
extract(epoch from okres)
from przelewc;

 declare r_nadawca numeric(24);
 declare r_adresat numeric(24);
 declare r_kwota int;
 declare r_tytul varchar;
 declare r_data numeric;
 declare r_faza numeric;
 declare r_okres numeric;
begin
 open my_cur;
 fetch my_cur into r_nadawca, r_adresat, r_kwota, r_tytul, r_data, r_faza, r_okres;
 while FOUND loop
  if (r_data - r_faza) / r_okres >= 1 then
   call przelew(r_nadawca, r_adresat, r_kwota, r_tytul);
  end if;
  fetch my_cur into r_nadawca, r_adresat, r_kwota, r_tytul, r_data, r_faza, r_okres;
 end loop;
 close my_cur;
end; $$;


ALTER PROCEDURE public.run_reccurent_payments() OWNER TO admin;

--
-- Name: adresowe; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.adresowe (
    id integer NOT NULL,
    mieszkanie character varying(255),
    budynek character varying(255) NOT NULL,
    ulica character varying(255),
    miejscowosc character varying(255) NOT NULL,
    poczta integer
);


ALTER TABLE public.adresowe OWNER TO admin;

--
-- Name: adresowe_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.adresowe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.adresowe_id_seq OWNER TO admin;

--
-- Name: adresowe_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.adresowe_id_seq OWNED BY public.adresowe.id;


--
-- Name: kontaktowe; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.kontaktowe (
    id integer NOT NULL,
    email character varying(255),
    teelefon integer
);


ALTER TABLE public.kontaktowe OWNER TO admin;

--
-- Name: kontaktowe_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.kontaktowe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kontaktowe_id_seq OWNER TO admin;

--
-- Name: kontaktowe_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.kontaktowe_id_seq OWNED BY public.kontaktowe.id;


--
-- Name: konto_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.konto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.konto_id_seq OWNER TO admin;

--
-- Name: konto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.konto_id_seq OWNED BY public.konto.id;


--
-- Name: logowania; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.logowania (
    id integer NOT NULL,
    login character varying NOT NULL,
    haslo character varying NOT NULL,
    autoryzacja2e character varying NOT NULL,
    zaufany character varying NOT NULL
);


ALTER TABLE public.logowania OWNER TO admin;

--
-- Name: logowania_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.logowania_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.logowania_id_seq OWNER TO admin;

--
-- Name: logowania_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.logowania_id_seq OWNED BY public.logowania.id;


--
-- Name: lokaty; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.lokaty (
    id integer NOT NULL,
    oprocentowanie integer NOT NULL,
    dlugosc interval NOT NULL
);


ALTER TABLE public.lokaty OWNER TO admin;

--
-- Name: lokaty_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.lokaty_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lokaty_id_seq OWNER TO admin;

--
-- Name: lokaty_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.lokaty_id_seq OWNED BY public.lokaty.id;


--
-- Name: osobowe; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.osobowe (
    id integer NOT NULL,
    imie character varying(255) NOT NULL,
    imie2 character varying(255),
    nazwisko character varying(255) NOT NULL,
    data date NOT NULL,
    pesel integer NOT NULL,
    dokument character varying(9) NOT NULL,
    termin date NOT NULL,
    can integer NOT NULL
);


ALTER TABLE public.osobowe OWNER TO admin;

--
-- Name: osobowe_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.osobowe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.osobowe_id_seq OWNER TO admin;

--
-- Name: osobowe_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.osobowe_id_seq OWNED BY public.osobowe.id;


--
-- Name: przelew; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.przelew (
    nadawca numeric(24,0) NOT NULL,
    adresat numeric(24,0) NOT NULL,
    kwota integer NOT NULL,
    data timestamp without time zone NOT NULL,
    tytul character varying(255) NOT NULL
);


ALTER TABLE public.przelew OWNER TO admin;

--
-- Name: przelewc; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.przelewc (
    id integer NOT NULL,
    nadawca numeric(24,0) NOT NULL,
    adresat numeric(24,0) NOT NULL,
    kwota integer NOT NULL,
    data timestamp without time zone NOT NULL,
    okres interval NOT NULL,
    faza timestamp without time zone NOT NULL,
    tytul character varying(255) NOT NULL
);


ALTER TABLE public.przelewc OWNER TO admin;

--
-- Name: przelewc_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.przelewc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.przelewc_id_seq OWNER TO admin;

--
-- Name: przelewc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.przelewc_id_seq OWNED BY public.przelewc.id;


--
-- Name: przelewz; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.przelewz (
    id integer NOT NULL,
    nadawca numeric(24,0) NOT NULL,
    adresat numeric(24,0) NOT NULL,
    kwota integer NOT NULL,
    data timestamp without time zone NOT NULL,
    tytul character varying(255) NOT NULL
);


ALTER TABLE public.przelewz OWNER TO admin;

--
-- Name: przelewz_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.przelewz_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.przelewz_id_seq OWNER TO admin;

--
-- Name: przelewz_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.przelewz_id_seq OWNED BY public.przelewz.id;


--
-- Name: usb; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.usb (
    d_logowania integer NOT NULL,
    d_osobowe integer NOT NULL,
    d_adresowe integer NOT NULL,
    konto integer NOT NULL,
    d_kontaktowe integer NOT NULL
);


ALTER TABLE public.usb OWNER TO admin;

--
-- Name: uzytkownicy; Type: VIEW; Schema: public; Owner: admin
--

CREATE VIEW public.uzytkownicy AS
 SELECT adresowe.ulica,
    adresowe.miejscowosc,
    adresowe.poczta,
    adresowe.mieszkanie,
    adresowe.budynek,
    osobowe.imie,
    osobowe.imie2,
    osobowe.nazwisko,
    osobowe.data,
    osobowe.pesel,
    osobowe.termin,
    osobowe.dokument,
    osobowe.can,
    kontaktowe.teelefon,
    kontaktowe.email
   FROM (((public.adresowe
     JOIN public.usb ON ((adresowe.id = usb.d_adresowe)))
     JOIN public.osobowe ON ((usb.d_osobowe = osobowe.id)))
     JOIN public.kontaktowe ON ((usb.d_kontaktowe = kontaktowe.id)));


ALTER VIEW public.uzytkownicy OWNER TO admin;

--
-- Name: adresowe id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.adresowe ALTER COLUMN id SET DEFAULT nextval('public.adresowe_id_seq'::regclass);


--
-- Name: kontaktowe id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.kontaktowe ALTER COLUMN id SET DEFAULT nextval('public.kontaktowe_id_seq'::regclass);


--
-- Name: konto id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.konto ALTER COLUMN id SET DEFAULT nextval('public.konto_id_seq'::regclass);


--
-- Name: logowania id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.logowania ALTER COLUMN id SET DEFAULT nextval('public.logowania_id_seq'::regclass);


--
-- Name: lokaty id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.lokaty ALTER COLUMN id SET DEFAULT nextval('public.lokaty_id_seq'::regclass);


--
-- Name: osobowe id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.osobowe ALTER COLUMN id SET DEFAULT nextval('public.osobowe_id_seq'::regclass);


--
-- Name: przelewc id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.przelewc ALTER COLUMN id SET DEFAULT nextval('public.przelewc_id_seq'::regclass);


--
-- Name: przelewz id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.przelewz ALTER COLUMN id SET DEFAULT nextval('public.przelewz_id_seq'::regclass);


--
-- Data for Name: adresowe; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.adresowe (id, mieszkanie, budynek, ulica, miejscowosc, poczta) FROM stdin;
1	10	4	Mickiewicza	Wrocław	80778
\.


--
-- Data for Name: kontaktowe; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.kontaktowe (id, email, teelefon) FROM stdin;
1	adam@kowalski.pl	555666444
\.


--
-- Data for Name: konto; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.konto (id, nr, srodki) FROM stdin;
2	109010140000071219812875	1000
1	109010140000071219812874	99850000
\.


--
-- Data for Name: logowania; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.logowania (id, login, haslo, autoryzacja2e, zaufany) FROM stdin;
1	adam	haslo	nie	nie
2	ola	haslo2	nie	nie
\.


--
-- Data for Name: lokata; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.lokata (lokata, konto, srodki, data) FROM stdin;
\.


--
-- Data for Name: lokaty; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.lokaty (id, oprocentowanie, dlugosc) FROM stdin;
1	10	1 year 6 mons
2	5	2 years
\.


--
-- Data for Name: osobowe; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.osobowe (id, imie, imie2, nazwisko, data, pesel, dokument, termin, can) FROM stdin;
1	adam	dawid	kowalski	2024-01-19	999999	999999999	2024-01-19	999
\.


--
-- Data for Name: przelew; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.przelew (nadawca, adresat, kwota, data, tytul) FROM stdin;
109010140000071219812875	109010140000071219812874	1000	2024-01-25 21:28:20.986986	aaaa
109010140000071219812874	109010140000071219812875	100	2024-01-26 08:23:46.550326	Haaa
109010140000071219812874	109010140000071219812875	100	2024-01-26 08:25:48.018326	AAA
109010140000071219812874	109010140000071219812875	100	2024-01-26 08:26:50.10316	aaa
109010140000071219812874	109010140000071219812875	1000000	2024-01-26 09:37:29.740337	109010140000071219812875
109010140000071219812874	109010140000071219812875	-199999900	2024-01-26 09:39:49.071305	Oddawaj moje pieniądze złodzieju
109010140000071219812874	109010140000071219812875	100000	2024-01-26 15:27:47.76	przeeleww
11112222333344445555	11112222333344445556	100	2024-02-02 08:31:34.993913	Shoudl work
109010140000071219812874	109010140000071219812875	100	2024-02-05 06:36:36.503567	Test
109010140000071219812874	109010140000071219812875	100000000	2024-02-05 06:36:53.995849	Test
109010140000071219812874	109010140000071219812875	10000	2024-02-05 06:37:15.929942	Test
109010140000071219812874	109010140000071219812875	10000	2024-02-05 06:37:32.036076	Test
109010140000071219812874	109010140000071219812875	10000	2024-02-05 06:37:32.282517	Test
109010140000071219812874	109010140000071219812875	10000	2024-02-05 06:37:32.528544	Test
109010140000071219812874	109010140000071219812875	10000	2024-02-05 06:37:32.756457	Test
109010140000071219812874	109010140000071219812875	10000	2024-02-05 06:37:32.950319	Test
109010140000071219812874	109010140000071219812875	100	2024-02-05 08:31:05.219082	Przelew cykliczny
109010140000071219812874	109010140000071219812875	100	2024-02-05 08:31:08.805895	Przelew cykliczny
109010140000071219812874	109010140000071219812875	100	2024-02-05 08:31:09.119694	Przelew cykliczny
\.


--
-- Data for Name: przelewc; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.przelewc (id, nadawca, adresat, kwota, data, okres, faza, tytul) FROM stdin;
1	109010140000071219812874	109010140000071219812875	100	2024-01-30 08:10:30.42408	1 day	1970-01-01 00:00:00	Przelew cykliczny
\.


--
-- Data for Name: przelewz; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.przelewz (id, nadawca, adresat, kwota, data, tytul) FROM stdin;
\.


--
-- Data for Name: usb; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.usb (d_logowania, d_osobowe, d_adresowe, konto, d_kontaktowe) FROM stdin;
1	1	1	1	1
\.


--
-- Name: adresowe_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.adresowe_id_seq', 1, false);


--
-- Name: kontaktowe_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.kontaktowe_id_seq', 1, false);


--
-- Name: konto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.konto_id_seq', 1, false);


--
-- Name: logowania_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.logowania_id_seq', 2, true);


--
-- Name: lokaty_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.lokaty_id_seq', 1, false);


--
-- Name: osobowe_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.osobowe_id_seq', 1, false);


--
-- Name: przelewc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.przelewc_id_seq', 1, false);


--
-- Name: przelewz_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.przelewz_id_seq', 1, false);


--
-- Name: adresowe adresowe_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.adresowe
    ADD CONSTRAINT adresowe_pkey PRIMARY KEY (id);


--
-- Name: konto fk_konto_nr; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.konto
    ADD CONSTRAINT fk_konto_nr UNIQUE (nr);


--
-- Name: kontaktowe kontaktowe_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.kontaktowe
    ADD CONSTRAINT kontaktowe_pkey PRIMARY KEY (id);


--
-- Name: konto konto_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.konto
    ADD CONSTRAINT konto_pkey PRIMARY KEY (id);


--
-- Name: logowania logowania_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.logowania
    ADD CONSTRAINT logowania_pkey PRIMARY KEY (id);


--
-- Name: lokaty lokaty_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.lokaty
    ADD CONSTRAINT lokaty_pkey PRIMARY KEY (id);


--
-- Name: osobowe osobowe_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.osobowe
    ADD CONSTRAINT osobowe_pkey PRIMARY KEY (id);


--
-- Name: przelewc przelewc_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.przelewc
    ADD CONSTRAINT przelewc_pkey PRIMARY KEY (id);


--
-- Name: przelewz przelewz_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.przelewz
    ADD CONSTRAINT przelewz_pkey PRIMARY KEY (id);


--
-- Name: adresowe_miejscowosc; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX adresowe_miejscowosc ON public.adresowe USING btree (miejscowosc);


--
-- Name: adresowe_poczta; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX adresowe_poczta ON public.adresowe USING btree (poczta);


--
-- Name: konto_nr; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX konto_nr ON public.konto USING btree (nr);


--
-- Name: konto_srodki; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX konto_srodki ON public.konto USING btree (srodki);


--
-- Name: lokata_data; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX lokata_data ON public.lokata USING btree (data);


--
-- Name: lokata_srodki; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX lokata_srodki ON public.lokata USING btree (srodki);


--
-- Name: osobowe_data; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX osobowe_data ON public.osobowe USING btree (data);


--
-- Name: osobowe_termin; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX osobowe_termin ON public.osobowe USING btree (termin);


--
-- Name: przelewc fk_przelewc_adresat; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.przelewc
    ADD CONSTRAINT fk_przelewc_adresat FOREIGN KEY (adresat) REFERENCES public.konto(nr);


--
-- Name: lokata fklokatakonto; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.lokata
    ADD CONSTRAINT fklokatakonto FOREIGN KEY (konto) REFERENCES public.konto(id);


--
-- Name: lokata fklokatalokata; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.lokata
    ADD CONSTRAINT fklokatalokata FOREIGN KEY (lokata) REFERENCES public.lokaty(id);


--
-- Name: usb fkusbadresowe; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.usb
    ADD CONSTRAINT fkusbadresowe FOREIGN KEY (d_adresowe) REFERENCES public.adresowe(id);


--
-- Name: usb fkusbkontaktowe; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.usb
    ADD CONSTRAINT fkusbkontaktowe FOREIGN KEY (d_kontaktowe) REFERENCES public.kontaktowe(id);


--
-- Name: usb fkusbkonto; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.usb
    ADD CONSTRAINT fkusbkonto FOREIGN KEY (konto) REFERENCES public.konto(id);


--
-- Name: usb fkusblogowania; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.usb
    ADD CONSTRAINT fkusblogowania FOREIGN KEY (d_logowania) REFERENCES public.logowania(id);


--
-- Name: usb fkusbosobowe; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.usb
    ADD CONSTRAINT fkusbosobowe FOREIGN KEY (d_osobowe) REFERENCES public.osobowe(id);


--
-- Name: TABLE konto; Type: ACL; Schema: public; Owner: admin
--

GRANT INSERT ON TABLE public.konto TO system;


--
-- Name: TABLE lokata; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.lokata TO system;


--
-- Name: TABLE adresowe; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adresowe TO system;


--
-- Name: TABLE kontaktowe; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.kontaktowe TO system;


--
-- Name: TABLE logowania; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.logowania TO system;


--
-- Name: TABLE osobowe; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.osobowe TO system;


--
-- Name: TABLE przelew; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT,INSERT,DELETE ON TABLE public.przelew TO system;


--
-- Name: TABLE przelewc; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT,INSERT,DELETE ON TABLE public.przelewc TO system;


--
-- Name: TABLE usb; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.usb TO system;


--
-- Name: TABLE uzytkownicy; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.uzytkownicy TO system;


--
-- PostgreSQL database dump complete
--

