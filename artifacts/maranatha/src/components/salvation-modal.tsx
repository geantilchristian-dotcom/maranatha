import { useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

interface SalvationModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  questions: string[];
  whatsappNumber: string | null | undefined;
}

export function SalvationModal({ open, onOpenChange, questions, whatsappNumber }: SalvationModalProps) {
  const [step, setStep] = useState(0);
  const [name, setName] = useState("");

  const handleNext = () => {
    if (step < 5) {
      setStep(step + 1);
    }
  };

  const resetAndClose = () => {
    setStep(0);
    setName("");
    onOpenChange(false);
  };

  const finish = () => {
    const message = encodeURIComponent(`Bonjour, je suis ${name}. Je viens de prier pour recevoir Jésus-Christ comme mon Seigneur et Sauveur à travers l'application Maranatha.`);
    const waNum = whatsappNumber ? whatsappNumber.replace(/\D/g, "") : "";
    window.open(`https://wa.me/${waNum}?text=${message}`, "_blank");
    resetAndClose();
  };

  return (
    <Dialog open={open} onOpenChange={(val) => {
      if (!val) resetAndClose();
      else onOpenChange(val);
    }}>
      <DialogContent className="sm:max-w-md rounded-xl">
        <DialogHeader>
          <DialogTitle className="font-serif text-2xl text-primary text-center">Recevoir Jésus</DialogTitle>
          <DialogDescription className="text-center">
            Un chemin vers une nouvelle vie
          </DialogDescription>
        </DialogHeader>

        <div className="py-6">
          {step === 0 && (
            <div className="space-y-4 animate-in fade-in slide-in-from-bottom-2">
              <div className="space-y-2">
                <Label htmlFor="name">Comment vous appelez-vous ?</Label>
                <Input 
                  id="name" 
                  value={name} 
                  onChange={(e) => setName(e.target.value)} 
                  placeholder="Votre nom"
                  className="bg-muted/50"
                  data-testid="salvation-input-name"
                />
              </div>
              <Button 
                onClick={handleNext} 
                disabled={!name.trim()} 
                className="w-full bg-primary hover:bg-primary/90 text-white"
                data-testid="salvation-btn-start"
              >
                Commencer
              </Button>
            </div>
          )}

          {step > 0 && step <= 4 && (
            <div className="space-y-6 animate-in fade-in slide-in-from-right-4">
              <p className="text-lg font-medium text-center leading-relaxed">
                {questions[step - 1] || "Question non définie"}
              </p>
              <div className="grid grid-cols-2 gap-4">
                <Button variant="outline" onClick={resetAndClose} data-testid={`salvation-btn-no-${step}`}>
                  Non
                </Button>
                <Button onClick={handleNext} className="bg-primary hover:bg-primary/90 text-white" data-testid={`salvation-btn-yes-${step}`}>
                  Oui, je le crois
                </Button>
              </div>
            </div>
          )}

          {step === 5 && (
            <div className="space-y-6 text-center animate-in zoom-in-95">
              <div className="w-16 h-16 bg-green-100 text-green-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinelinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
              </div>
              <h3 className="font-serif text-2xl text-foreground">Félicitations {name} !</h3>
              <p className="text-muted-foreground">
                Les anges dans les cieux se réjouissent. Nous aimerions vous accompagner dans cette nouvelle vie.
              </p>
              <Button onClick={finish} className="w-full bg-[#25D366] hover:bg-[#20bd5a] text-white gap-2" data-testid="salvation-btn-whatsapp">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinelinejoin="round"><path d="M3 21l1.65-3.8a9 9 0 1 1 3.4 2.9L3 21"/><path d="M9 10a.5.5 0 0 0 1 0V9a.5.5 0 0 0-1 0v1Z"/><path d="M14 10a.5.5 0 0 0 1 0V9a.5.5 0 0 0-1 0v1Z"/><path d="M9.5 13.5c.5 1 1.5 1 2.5 1s2-.5 2.5-1"/></svg>
                Nous écrire sur WhatsApp
              </Button>
            </div>
          )}
        </div>
        
        <div className="flex justify-center space-x-1 mt-4">
          {[0, 1, 2, 3, 4, 5].map((i) => (
            <div key={i} className={`h-1.5 w-1.5 rounded-full ${i === step ? 'bg-primary' : 'bg-muted'}`} />
          ))}
        </div>
      </DialogContent>
    </Dialog>
  );
}
