import { useState } from "react";
import { useGetDiffusion, getGetDiffusionQueryKey } from "@workspace/api-client-react";
import { AudioPlayer } from "@/components/audio-player";
import { SalvationModal } from "@/components/salvation-modal";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { BookOpen, Calendar, HeartHandshake, Phone, Home as HomeIcon, Youtube, Radio } from "lucide-react";
import { SiWhatsapp } from "react-icons/si";

export default function Home() {
  const { data: diffusion, isLoading } = useGetDiffusion({
    query: {
      refetchInterval: 5000, // Poll every 5s
    },
  });

  const [modalOpen, setModalOpen] = useState(false);

  const questions = diffusion ? [
    diffusion.q1 || "Croyez-vous que Jésus-Christ est le Fils de Dieu ?",
    diffusion.q2 || "Croyez-vous qu'il est mort sur la croix pour vos péchés ?",
    diffusion.q3 || "Croyez-vous qu'il est ressuscité d'entre les morts ?",
    diffusion.q4 || "Voulez-vous l'inviter dans votre cœur comme Seigneur et Sauveur ?"
  ] : [];

  const handleDonationWa = () => {
    if (diffusion?.n_whatsapp) {
      const waNum = diffusion.n_whatsapp.replace(/\D/g, "");
      const message = encodeURIComponent("Bonjour, voici la capture de mon don pour l'œuvre de Dieu.");
      window.open(`https://wa.me/${waNum}?text=${message}`, "_blank");
    }
  };

  return (
    <div className="min-h-[100dvh] bg-background w-full flex justify-center">
      <div className="w-full max-w-[450px] bg-background shadow-2xl relative flex flex-col">
        {/* Header */}
        <header className="sticky top-0 z-50 bg-background/95 backdrop-blur-md border-b border-border px-4 py-3 flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <h1 className="font-serif font-bold text-2xl tracking-tighter text-primary">MARANATHA</h1>
            <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center">
              <Radio className="w-4 h-4 text-primary animate-pulse" />
            </div>
          </div>
          <nav className="flex items-center justify-between text-xs font-semibold text-muted-foreground pb-1">
            <a href="#accueil" className="hover:text-primary transition-colors flex flex-col items-center gap-1">
              <HomeIcon className="w-4 h-4" /> Accueil
            </a>
            <a href="#biblio" className="hover:text-primary transition-colors flex flex-col items-center gap-1">
              <BookOpen className="w-4 h-4" /> Biblio
            </a>
            <a href="#programme" className="hover:text-primary transition-colors flex flex-col items-center gap-1">
              <Calendar className="w-4 h-4" /> Programme
            </a>
            <a href="#dons" className="hover:text-primary transition-colors flex flex-col items-center gap-1">
              <HeartHandshake className="w-4 h-4" /> Dons
            </a>
          </nav>
        </header>

        <main className="flex-1 overflow-y-auto overflow-x-hidden scroll-smooth pb-12">
          {/* Accueil & Player */}
          <section id="accueil" className="p-4 pt-6 space-y-6">
            <Button 
              className="w-full bg-gradient-to-r from-red-600 to-red-800 hover:from-red-700 hover:to-red-900 text-white shadow-xl shadow-red-900/20 py-6 text-lg font-bold uppercase tracking-widest rounded-xl border-none"
              onClick={() => setModalOpen(true)}
              data-testid="btn-recevoir-jesus"
            >
              Recevoir Jésus-Christ
            </Button>

            <AudioPlayer 
              url={diffusion?.audio} 
              title={diffusion?.titre || "En attente de diffusion..."} 
              coverArt={diffusion?.pochette} 
            />

            {diffusion?.v_txt && (
              <Card className="border-l-4 border-l-secondary bg-secondary/5 border-y-0 border-r-0 shadow-none">
                <CardContent className="p-4">
                  <p className="font-serif italic text-lg leading-relaxed text-foreground">
                    "{diffusion.v_txt}"
                  </p>
                  {diffusion.v_ref && (
                    <p className="text-right text-sm font-bold text-primary mt-2 uppercase tracking-wide">
                      — {diffusion.v_ref}
                    </p>
                  )}
                </CardContent>
              </Card>
            )}
          </section>

          {/* Programme */}
          <section id="programme" className="p-4 pt-8 space-y-4">
            <div className="flex items-center gap-2 mb-4">
              <Calendar className="text-primary w-5 h-5" />
              <h2 className="font-sans font-bold text-xl uppercase tracking-wider text-foreground">Programme</h2>
            </div>
            
            <div className="grid gap-3">
              <div className="bg-card border border-border p-4 rounded-xl flex justify-between items-center shadow-sm">
                <div>
                  <h3 className="font-bold text-primary">{diffusion?.t_matin || "Culte Matinal"}</h3>
                  <p className="text-sm text-muted-foreground">Dimanche</p>
                </div>
                <div className="bg-primary/10 text-primary font-mono font-bold px-3 py-1 rounded-lg">
                  {diffusion?.h_matin || "08:00 - 11:30"}
                </div>
              </div>
              <div className="bg-card border border-border p-4 rounded-xl flex justify-between items-center shadow-sm">
                <div>
                  <h3 className="font-bold text-primary">{diffusion?.t_soir || "Culte du Soir"}</h3>
                  <p className="text-sm text-muted-foreground">Mercredi & Vendredi</p>
                </div>
                <div className="bg-primary/10 text-primary font-mono font-bold px-3 py-1 rounded-lg">
                  {diffusion?.h_soir || "16:00 - 18:00"}
                </div>
              </div>
            </div>
          </section>

          {/* Bibliothèque (Static grid) */}
          <section id="biblio" className="p-4 pt-8 bg-muted/30 mt-4 border-y border-border">
            <div className="flex items-center gap-2 mb-4">
              <BookOpen className="text-primary w-5 h-5" />
              <h2 className="font-sans font-bold text-xl uppercase tracking-wider text-foreground">Bibliothèque</h2>
            </div>
            <div className="grid grid-cols-2 gap-3">
              {['Prédications', 'Louanges', 'Témoignages', 'Vidéos'].map((cat, i) => (
                <div key={i} className="aspect-square bg-card border border-border rounded-xl flex flex-col items-center justify-center p-4 hover:border-primary/50 transition-colors cursor-pointer group shadow-sm">
                  {i === 3 ? <Youtube className="w-8 h-8 mb-2 text-red-500 group-hover:scale-110 transition-transform" /> : <BookOpen className="w-8 h-8 mb-2 text-primary/70 group-hover:scale-110 transition-transform" />}
                  <span className="font-bold text-sm text-foreground">{cat}</span>
                </div>
              ))}
            </div>
          </section>

          {/* Dons */}
          <section id="dons" className="p-4 pt-8 space-y-4">
            <div className="flex items-center gap-2 mb-4">
              <HeartHandshake className="text-primary w-5 h-5" />
              <h2 className="font-sans font-bold text-xl uppercase tracking-wider text-foreground">Soutenir L'Œuvre</h2>
            </div>

            <div className="space-y-3">
              {[
                { name: "Airtel Money", num: diffusion?.n_airtel || "+243 000 000 000", color: "bg-red-50 text-red-700 border-red-200" },
                { name: "Orange Money", num: diffusion?.n_orange || "+243 000 000 000", color: "bg-orange-50 text-orange-700 border-orange-200" },
                { name: "M-Pesa (Voda)", num: diffusion?.n_voda || "+243 000 000 000", color: "bg-blue-50 text-blue-700 border-blue-200" }
              ].map((m, i) => (
                <div key={i} className={`border p-4 rounded-xl flex justify-between items-center ${m.color}`}>
                  <span className="font-bold">{m.name}</span>
                  <span className="font-mono font-medium">{m.num}</span>
                </div>
              ))}
            </div>

            <Button 
              onClick={handleDonationWa}
              className="w-full bg-[#25D366] hover:bg-[#20bd5a] text-white py-6 rounded-xl mt-4 gap-2"
              data-testid="btn-don-whatsapp"
            >
              <SiWhatsapp className="w-5 h-5" />
              Envoyer la capture par WhatsApp
            </Button>
          </section>

        </main>

        <footer className="bg-zinc-950 text-zinc-400 p-6 text-center text-sm">
          <p className="font-serif text-zinc-300 text-lg mb-2">Maranatha Ministère</p>
          <p>Bukavu, Sud-Kivu, RDC</p>
          <p className="mt-4 text-xs opacity-50">© {new Date().getFullYear()} Tous droits réservés.</p>
        </footer>

        <SalvationModal 
          open={modalOpen} 
          onOpenChange={setModalOpen} 
          questions={questions}
          whatsappNumber={diffusion?.n_whatsapp}
        />
      </div>
    </div>
  );
}
