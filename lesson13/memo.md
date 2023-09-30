## delegatecall
コントラクト A がコントラクト B への delegatecall を実行すると、B のコードが実行される。
この時、contract A のStorage、msg.sender および msg.value を使用される。 
storageslotの名前は違っても良いが順番、型がとても重要。
