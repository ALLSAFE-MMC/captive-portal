from zeep import Client

def verify_identity(tc_kimlik_no, ad, soyad, dogum_yili):
    client = Client('https://tckimlik.nvi.gov.tr/Service/KPSPublic.asmx?WSDL')
    try:
        result = client.service.TCKimlikNoDogrula(
            TCKimlikNo=tc_kimlik_no,
            Ad=ad,
            Soyad=soyad,
            DogumYili=dogum_yili
        )
        return result
    except Exception as e:
        print(f"Error verifying identity: {e}")
        return False
