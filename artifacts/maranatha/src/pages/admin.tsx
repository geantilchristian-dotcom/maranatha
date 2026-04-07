import { useState, useEffect, useRef } from "react";
import { useGetDiffusion, getGetDiffusionQueryKey, useUpdateSermon } from "@workspace/api-client-react";
import { useQueryClient } from "@tanstack/react-query";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { useToast } from "@/hooks/use-toast";
import { Loader2, Upload, Settings, List, Phone, Save } from "lucide-react";

export default function Admin() {
  const { data: diffusion, isLoading } = useGetDiffusion();
  const updateSermon = useUpdateSermon();
  const queryClient = useQueryClient();
  const { toast } = useToast();

  const [formData, setFormData] = useState<any>({});
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [isUploading, setIsUploading] = useState(false);
  const initialized = useRef(false);

  useEffect(() => {
    if (diffusion && !initialized.current) {
      setFormData(diffusion);
      initialized.current = true;
    }
  }, [diffusion]);

  const handleChange = (field: string, value: string) => {
    setFormData((prev: any) => ({ ...prev, [field]: value }));
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setAudioFile(e.target.files[0]);
    }
  };

  const handleSaveText = () => {
    updateSermon.mutate(
      { data: formData },
      {
        onSuccess: (data) => {
          queryClient.setQueryData(getGetDiffusionQueryKey(), data);
          toast({ title: "Modifications enregistrées" });
        },
        onError: () => {
          toast({ title: "Erreur lors de l'enregistrement", variant: "destructive" });
        }
      }
    );
  };

  const handleUploadAndSave = async () => {
    if (!audioFile) {
      handleSaveText();
      return;
    }

    setIsUploading(true);
    setUploadProgress(10);
    
    try {
      const data = new FormData();
      data.append("audioFile", audioFile);
      data.append("jsonData", JSON.stringify(formData));

      const xhr = new XMLHttpRequest();
      xhr.open("POST", "/api/update-sermon", true);

      xhr.upload.onprogress = (e) => {
        if (e.lengthComputable) {
          const percentComplete = Math.round((e.loaded / e.total) * 100);
          setUploadProgress(percentComplete);
        }
      };

      xhr.onload = () => {
        if (xhr.status === 200) {
          const res = JSON.parse(xhr.responseText);
          queryClient.setQueryData(getGetDiffusionQueryKey(), res);
          toast({ title: "Diffusion publiée avec succès" });
          setAudioFile(null);
        } else {
          toast({ title: "Erreur de publication", variant: "destructive" });
        }
        setIsUploading(false);
        setUploadProgress(0);
      };

      xhr.onerror = () => {
        toast({ title: "Erreur réseau", variant: "destructive" });
        setIsUploading(false);
        setUploadProgress(0);
      };

      xhr.send(data);
    } catch (err) {
      toast({ title: "Erreur inattendue", variant: "destructive" });
      setIsUploading(false);
      setUploadProgress(0);
    }
  };

  if (isLoading) {
    return <div className="min-h-screen flex items-center justify-center"><Loader2 className="animate-spin w-8 h-8 text-primary" /></div>;
  }

  return (
    <div className="min-h-screen bg-muted/20 flex flex-col md:flex-row">
      <div className="w-full md:w-64 bg-card border-r border-border p-6 flex flex-col gap-6">
        <div>
          <h1 className="font-serif font-bold text-2xl text-primary mb-1">MARANATHA</h1>
          <p className="text-xs text-muted-foreground uppercase tracking-widest">Admin Panel</p>
        </div>
      </div>

      <div className="flex-1 p-6 md:p-12 max-w-4xl">
        <Tabs defaultValue="diffusion" className="w-full">
          <TabsList className="grid w-full grid-cols-4 mb-8 h-auto p-1 bg-muted/50 rounded-xl">
            <TabsTrigger value="diffusion" className="py-3 rounded-lg data-[state=active]:bg-background data-[state=active]:shadow-sm"><Upload className="w-4 h-4 mr-2 hidden sm:block" /> Diffusion</TabsTrigger>
            <TabsTrigger value="salut" className="py-3 rounded-lg data-[state=active]:bg-background data-[state=active]:shadow-sm"><Settings className="w-4 h-4 mr-2 hidden sm:block" /> Salut</TabsTrigger>
            <TabsTrigger value="programme" className="py-3 rounded-lg data-[state=active]:bg-background data-[state=active]:shadow-sm"><List className="w-4 h-4 mr-2 hidden sm:block" /> Programme</TabsTrigger>
            <TabsTrigger value="dons" className="py-3 rounded-lg data-[state=active]:bg-background data-[state=active]:shadow-sm"><Phone className="w-4 h-4 mr-2 hidden sm:block" /> Dons</TabsTrigger>
          </TabsList>

          <TabsContent value="diffusion" className="space-y-6">
            <Card className="border-none shadow-md">
              <CardHeader>
                <CardTitle>Nouvelle Diffusion</CardTitle>
                <CardDescription>Configurez la prédication en cours</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label>Titre du message</Label>
                  <Input value={formData.titre || ""} onChange={(e) => handleChange("titre", e.target.value)} data-testid="admin-input-titre" />
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Référence Biblique</Label>
                    <Input value={formData.v_ref || ""} onChange={(e) => handleChange("v_ref", e.target.value)} placeholder="Ex: Jean 3:16" data-testid="admin-input-vref" />
                  </div>
                  <div className="space-y-2">
                    <Label>URL de la pochette (Image)</Label>
                    <Input value={formData.pochette || ""} onChange={(e) => handleChange("pochette", e.target.value)} placeholder="https://..." data-testid="admin-input-pochette" />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label>Texte du verset</Label>
                  <Textarea value={formData.v_txt || ""} onChange={(e) => handleChange("v_txt", e.target.value)} className="min-h-[100px]" data-testid="admin-input-vtxt" />
                </div>

                <div className="space-y-2 pt-4 border-t border-border">
                  <Label>Fichier Audio (MP3)</Label>
                  <Input type="file" accept="audio/*" onChange={handleFileChange} data-testid="admin-input-audio" />
                  {audioFile && <p className="text-sm text-muted-foreground mt-1">Fichier sélectionné : {audioFile.name}</p>}
                </div>

                {isUploading && (
                  <div className="space-y-2 pt-2">
                    <div className="flex justify-between text-xs text-muted-foreground">
                      <span>Téléchargement en cours...</span>
                      <span>{uploadProgress}%</span>
                    </div>
                    <Progress value={uploadProgress} className="h-2" />
                  </div>
                )}

                <Button 
                  onClick={handleUploadAndSave} 
                  disabled={isUploading || updateSermon.isPending}
                  className="w-full mt-6 bg-primary hover:bg-primary/90"
                  data-testid="admin-btn-publish"
                >
                  {isUploading ? (
                    <><Loader2 className="w-4 h-4 mr-2 animate-spin" /> Publication...</>
                  ) : (
                    <><Upload className="w-4 h-4 mr-2" /> Publier la diffusion</>
                  )}
                </Button>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="salut" className="space-y-6">
            <Card className="border-none shadow-md">
              <CardHeader>
                <CardTitle>Questions du Salut</CardTitle>
                <CardDescription>Les 4 questions posées à l'utilisateur</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {[1, 2, 3, 4].map((num) => (
                  <div key={num} className="space-y-2">
                    <Label>Question {num}</Label>
                    <Input 
                      value={formData[`q${num}`] || ""} 
                      onChange={(e) => handleChange(`q${num}`, e.target.value)} 
                      data-testid={`admin-input-q${num}`}
                    />
                  </div>
                ))}
                <Button onClick={handleSaveText} disabled={updateSermon.isPending} className="mt-4" data-testid="admin-btn-save-salut">
                  <Save className="w-4 h-4 mr-2" /> Enregistrer
                </Button>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="programme" className="space-y-6">
            <Card className="border-none shadow-md">
              <CardHeader>
                <CardTitle>Programme des Cultes</CardTitle>
              </CardHeader>
              <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div className="space-y-4">
                  <h3 className="font-bold border-b pb-2">Culte Matinal</h3>
                  <div className="space-y-2">
                    <Label>Titre</Label>
                    <Input value={formData.t_matin || ""} onChange={(e) => handleChange("t_matin", e.target.value)} />
                  </div>
                  <div className="space-y-2">
                    <Label>Heures</Label>
                    <Input value={formData.h_matin || ""} onChange={(e) => handleChange("h_matin", e.target.value)} placeholder="Ex: 08:00 - 11:30" />
                  </div>
                </div>

                <div className="space-y-4">
                  <h3 className="font-bold border-b pb-2">Culte du Soir</h3>
                  <div className="space-y-2">
                    <Label>Titre</Label>
                    <Input value={formData.t_soir || ""} onChange={(e) => handleChange("t_soir", e.target.value)} />
                  </div>
                  <div className="space-y-2">
                    <Label>Heures</Label>
                    <Input value={formData.h_soir || ""} onChange={(e) => handleChange("h_soir", e.target.value)} placeholder="Ex: 16:00 - 18:00" />
                  </div>
                </div>
                
                <div className="md:col-span-2">
                  <Button onClick={handleSaveText} disabled={updateSermon.isPending} data-testid="admin-btn-save-prog">
                    <Save className="w-4 h-4 mr-2" /> Enregistrer le programme
                  </Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="dons" className="space-y-6">
            <Card className="border-none shadow-md">
              <CardHeader>
                <CardTitle>Numéros de Téléphone</CardTitle>
                <CardDescription>Pour les dons et le contact WhatsApp</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4 grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Airtel Money</Label>
                  <Input value={formData.n_airtel || ""} onChange={(e) => handleChange("n_airtel", e.target.value)} />
                </div>
                <div className="space-y-2">
                  <Label>Orange Money</Label>
                  <Input value={formData.n_orange || ""} onChange={(e) => handleChange("n_orange", e.target.value)} />
                </div>
                <div className="space-y-2">
                  <Label>M-Pesa (Vodacom)</Label>
                  <Input value={formData.n_voda || ""} onChange={(e) => handleChange("n_voda", e.target.value)} />
                </div>
                <div className="space-y-2">
                  <Label>Numéro WhatsApp</Label>
                  <Input value={formData.n_whatsapp || ""} onChange={(e) => handleChange("n_whatsapp", e.target.value)} placeholder="Avec code pays (ex: 243...)" />
                </div>

                <div className="md:col-span-2 mt-4">
                  <Button onClick={handleSaveText} disabled={updateSermon.isPending} data-testid="admin-btn-save-dons">
                    <Save className="w-4 h-4 mr-2" /> Enregistrer les numéros
                  </Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

        </Tabs>
      </div>
    </div>
  );
}
