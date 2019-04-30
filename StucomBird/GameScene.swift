//
//  GameScene.swift
//  StucomBird
//
//  Created by DAM on 10/4/18.
//  Copyright © 2018 DAM. All rights reserved.
//

import SpriteKit
import GameplayKit

// Necesario para tratar con colisiones SKPhysicsContactDelegate
class GameScene: SKScene, SKPhysicsContactDelegate {
    // Alien spawning
    var gameTimer:Timer!
    var hazards = [ "mine", "torpedo"]

        // Collision categories
    let photonTorperdoCategory:UInt32 = 0x1 << 0
    let hazardCategory:UInt32 = 0x1 << 1
    let playerCategory:UInt32 = 0x1 << 2
    
    // Guía oficial de Apple sobre SpriteKit
    /* https://developer.apple.com/documentation/spritekit */
    
    // Scene: es el nodo raíz de todos los objetos SpriteKit que se desplegarán en una vista.
    // Para desplegar una "scene" tienes que presentarla desde un objeto SKView
    // Node: un nodo es el bloque fundamental de construcción de casi todo el contenido en SpriteKit.
    // Un nodo puede estar vacío y no dibujar nada en pantalla, para poder dibujar algo en pantalla
    // hay que utilizar subclases de SKNode, por ejemplo SKSpriteNode para dibujar un sprite.
    // SpriteNode: Para crear un SpriteNode, es necesario una textura (imagen) y de un Frame, el cual
    // contiene un rectángulo que define el área que cubrirá el SpriteNode
    // Todo SpriteNode tiene una posición (position) y un punto de anclado (Anchor Point)
    // El punto de anclado de un nodo Sprite es la propiedad que determina que punto de su
    // "Frame" está situado en la posición del sprite (por defecto - (0.5, 0.5) en medio - va de 0.0 a 1.0)
    
    // La propiedad categoryBitMask es un número que define el tipo de objeto que el cuerpo físico del nodo
    // tendrá y es considerado para las colisiones y contactos.
    // La propiedad collisionBitMask es un número que define con qué categorías de objeto este nodo debería colisionar
    // La propiedad contactTestBitMask es un número que define qué colisiones no serán notificadas
    // Si le das a un nodo números de Collision BitMask pero no le das números de contactTestBitMask, significa
    // que los nodos podrán colisionar pero no tendrás manera de saber cuándo ocurrió en código (no se notifica al sistema)
    // Si haces lo contraro (no collisionBitMask pero si contactTestBitMask), no chocarán o colisionarán, pero
    // el sistema te podrá notificar el momento en que tuvieron contacto.
    // Si a las dos propiedades les das valores entonces notificará y a la vez los nodos podrán colisionar
    // De forma predeterminada los cuerpos físicos tienen su propiedad collisionBitMask a todo y su
    // contactBitMask a nada
    
    // Todo elemento en pantalla es un nodo
    
    // Nodo de tipo SpriteKit para la mosquita
    var mosquita = SKSpriteNode()
    // Nodo para el fondo de la pantalla
    var fondo = SKSpriteNode()
    
    // Nodo label para la puntuacion
    var labelPuntuacion = SKLabelNode()
    var puntuacion = 0
    
    // Nodos para los tubos
    var tubo1 = SKSpriteNode()
    var tubo2 = SKSpriteNode()
    
    // Texturas de la mosquita
    var texturaMosca1 = SKTexture()
    var texturaMosca2 = SKTexture()
    var texturaMosca3 = SKTexture()
    var texturaMosca4 = SKTexture()
    
    // Textura de los tubos
    var texturaTubo1 = SKTexture()
    var texturaTubo2 = SKTexture()
    
    // altura de los huecos
    var alturaHueco = CGFloat()
    
    // timer para crear tubos y huecos
    var timer = Timer()
    // boolean para saber si el juego está activo o finalizado
    var gameOver = false
    
    // Variables para mostrar tubos de forma aleatoria
    var cantidadAleatoria = CGFloat()
    var compensacionTubos = CGFloat()
    
    // Enumeración de los nodos que pueden colisionar
    // se les debe representar con números potencia de 2
    enum tipoNodo: UInt32 {
        case mosquita = 1       // La mosquita colisiona
        case tuboSuelo = 2      // Si choca con el suelo o tubería perderá
        case huecoTubos = 4     // si pasa entre las tuberías subirá la puntuación
    }
    
    // Función equivalente a viewDidLoad
    override func didMove(to view: SKView) {
        // Nos encargamos de las colisiones de nuestros nodos
        self.physicsWorld.contactDelegate = self
       reiniciar()
       
    }
    
    func reiniciar() {
        // Creamos los tubos de manera constante e indefinidamente
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.setObstacles), userInfo: nil, repeats: true)
    let hazardTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.addHazard), userInfo: nil, repeats: true)
        
        // Ponemos la etiqueta con la puntuacion
        ponerPuntuacion()
        
        
        // El orden al poner los elementos es importante, el último tapa al anterior
        // Se puede gestionar también con la posición z de los sprite
        
        sharkAnimation()
        // Definimos la altura de los huecos
        alturaHueco = mosquita.size.height * 2
        crearFondoConAnimacion()
        crearSuelo()
        setObstacles()
    }
    
    func ponerPuntuacion() {
        labelPuntuacion.fontName = "Arial"
        labelPuntuacion.fontSize = 80
        labelPuntuacion.text = "0"
        labelPuntuacion.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 500)
        labelPuntuacion.zPosition = 2
        self.addChild(labelPuntuacion)
        
    }
    
   
    
   
    @objc func setObstacles() {
        
        // Acción para mover los tubos
        let moveObstacles = SKAction.move(by: CGVector(dx: -3 * self.frame.width, dy: 0), duration: TimeInterval(self.frame.width / 80))
        
        // Acción para borrar los tubos cuando desaparecen de la pantalla para no tener infinitos nodos en la aplicación
        let deleteObstacles = SKAction.removeFromParent()
        
        
        // Acción que enlaza las dos acciones (la que pone tubos y la que los borra)
        let moveDeleteObstacles = SKAction.sequence([moveObstacles, deleteObstacles])
        
        // Numero entre 0 y la mitad de alto de la pantalla (para que los tubos aparezcan a alturas diferentes)
        cantidadAleatoria = CGFloat(arc4random() % UInt32(self.frame.height/2))
        
        // Compensación para evitar que a veces salga un único tubo porque el otro está fuera de la pantalla
        compensacionTubos = cantidadAleatoria - self.frame.height / 4
        
        let hookTexture = SKTexture(imageNamed: "hook2.png")
        let hook = SKSpriteNode(texture: hookTexture)
        hook.position = CGPoint(x: self.frame.midX + self.frame.width, y: self.frame.midY + hookTexture.size().height / 2 + alturaHueco + compensacionTubos)
        hook.zPosition = 0
        
        // Le damos cuerpo físico al tubo
        hook.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "hook2"), alphaThreshold: 0.5, size: hook.size)
        // Para que no caiga
        hook.physicsBody!.isDynamic = false
        
        // Categoría de collision
        hook.physicsBody!.categoryBitMask = tipoNodo.tuboSuelo.rawValue
        
        // con quien colisiona
        hook.physicsBody!.collisionBitMask = tipoNodo.mosquita.rawValue
        
        // Hace contacto con
        hook.physicsBody!.contactTestBitMask = tipoNodo.mosquita.rawValue
        
        hook.run(moveDeleteObstacles)
        
        self.addChild(hook)
        
        texturaTubo2 = SKTexture(imageNamed: "ship.png")
        tubo2.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "ship"), alphaThreshold: 0.5, size: tubo2.size)
        tubo2.position = CGPoint(x: self.frame.midX + self.frame.width, y: self.frame.midY - texturaTubo2.size().height / 2 - alturaHueco + compensacionTubos)
        tubo2.zPosition = 0
        tubo2.run(moveDeleteObstacles)
        tubo2.physicsBody = SKPhysicsBody(rectangleOf: texturaTubo2.size())
        tubo2.physicsBody!.isDynamic = false
        tubo2.physicsBody!.categoryBitMask = tipoNodo.tuboSuelo.rawValue
        tubo2.physicsBody!.collisionBitMask = tipoNodo.mosquita.rawValue
        tubo2.physicsBody!.contactTestBitMask = tipoNodo.mosquita.rawValue
        self.addChild(tubo2)
        
        // Hueco entre los tubos
        let nodoHueco = SKSpriteNode()
        
        nodoHueco.position = CGPoint(x: self.frame.midX + self.frame.width, y: self.frame.midY + compensacionTubos)
        nodoHueco.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: hookTexture.size().width, height: alturaHueco))
        nodoHueco.physicsBody!.isDynamic = false
        
        // Asignamos su categoría
        nodoHueco.physicsBody!.categoryBitMask = tipoNodo.huecoTubos.rawValue
        // no queremos que colisione para que la mosca pueda pasar
        nodoHueco.physicsBody!.collisionBitMask = 0
        // Hace contacto con la mosquita
        nodoHueco.physicsBody!.contactTestBitMask = tipoNodo.mosquita.rawValue
        
        nodoHueco.zPosition = 1
        nodoHueco.run(moveDeleteObstacles)
        
        self.addChild(nodoHueco)
        
    }
    
    func crearSuelo() {
        let suelo = SKNode()
        suelo.position = CGPoint(x: -self.frame.midX, y: -self.frame.height / 2)
        suelo.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.width, height: 1))
        // el suelo se tiene que estar quieto
        suelo.physicsBody!.isDynamic = false
        
        // Categoría para collision
        suelo.physicsBody!.categoryBitMask = tipoNodo.tuboSuelo.rawValue
        // Colisiona con la mosquita
        suelo.physicsBody!.collisionBitMask = tipoNodo.mosquita.rawValue
        // contacto con el suelo
        suelo.physicsBody!.contactTestBitMask = tipoNodo.mosquita.rawValue
        
        self.addChild(suelo)
    }
    
    func crearFondoConAnimacion() {
        // Textura para el fondo
        let texturaFondo = SKTexture(imageNamed: "sea1.png")
        
        // Acciones del fondo (para hacer ilusión de movimiento)
        // Desplazamos en el eje de las x cada 0.3s
        let movimientoFondo = SKAction.move(by: CGVector(dx: -texturaFondo.size().width, dy: 0), duration: 4)
        
        let movimientoFondoOrigen = SKAction.move(by: CGVector(dx: texturaFondo.size().width, dy: 0), duration: 0)
        
        // repetimos hasta el infinito
        let movimientoInfinitoFondo = SKAction.repeatForever(SKAction.sequence([movimientoFondo, movimientoFondoOrigen]))
        
        // Necesitamos más de un fondo para que no se vea la pantalla en negro
        
        // contador de fondos
        var i: CGFloat = 0
        
        while i < 2 {
            // Le ponemos la textura al fondo
            fondo = SKSpriteNode(texture: texturaFondo)
        
            // Indicamos la posición inicial del fondo
            fondo.position = CGPoint(x: texturaFondo.size().width * i, y: self.frame.midY)
        
            // Estiramos la altura de la imagen para que se adapte al alto de la pantalla
            fondo.size.height = self.frame.height
        
            // Indicamos zPosition para que quede detrás de todo
            fondo.zPosition = -1
        
            // Aplicamos la acción
            fondo.run(movimientoInfinitoFondo)
            // Ponemos el fondo en la escena
            self.addChild(fondo)
            
            // Incrementamos contador
            i += 1
        }
        
    }
    
    func sharkAnimation() {
        // Asignamos las texturas de la mosquita
        texturaMosca1 = SKTexture(imageNamed: "sharkv1.png")
        texturaMosca2 = SKTexture(imageNamed: "sharkv1.png")
        texturaMosca3 = SKTexture(imageNamed: "sharkv4.png")
        texturaMosca4 = SKTexture(imageNamed: "sharkv4.png")
        
        // Creamos la animación que va intercambiando las texturas
        // para que parezca que la mosca va volando
        
        // Acción que indica las texturas y el tiempo de cada uno
        let animacion = SKAction.animate(with: [texturaMosca1, texturaMosca2, texturaMosca3, texturaMosca4], timePerFrame: 0.2)
        
        // Creamos la acción que hace que se vaya cambiando de textura
        // infinitamente
        let animacionInfinita = SKAction.repeatForever(animacion)
        
        // Le ponemos la textura inicial al nodo
        mosquita = SKSpriteNode(texture: texturaMosca1)
        // Posición inicial en la que ponemos a la mosquita
        // (0.0, 0.0) es el medio de la pantalla
        // Se puede poner 0.0, 0.0 o bien con referencia a la pantalla
        mosquita.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        
        // Le damos propiedades físicias a nuestra mosquita
        // Le damos un cuerpo circular
        mosquita.physicsBody = SKPhysicsBody(circleOfRadius: texturaMosca1.size().height / 2)
        
        // Al inicial la mosquita está quieta
        mosquita.physicsBody?.isDynamic = true
        
        // Añadimos su categoría
        mosquita.physicsBody!.categoryBitMask = tipoNodo.mosquita.rawValue
        
        // Indicamos la categoría de colisión con el suelo/tubos
        mosquita.physicsBody!.collisionBitMask = tipoNodo.tuboSuelo.rawValue
        
        // Hace contacto con (para que nos avise)
        mosquita.physicsBody!.contactTestBitMask = tipoNodo.tuboSuelo.rawValue | tipoNodo.huecoTubos.rawValue
        
        // Aplicamos la animación a la mosquita
        mosquita.run(animacionInfinita)
        
        mosquita.zPosition = 0
        
        // Ponemos la mosquita en la escena
        self.addChild(mosquita)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if gameOver == false {
            // En cuanto el usuario toque la pantalla le damos dinámica a la mosquita (caerá)
            mosquita.physicsBody!.isDynamic = true
            
            // Le damos una velocidad a la mosquita para que la velocidad al caer sea constante
            mosquita.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
            
            // Le aplicamos un impulso a la mosquita para que suba cada vez que pulsemos la pantalla
            // Y así poder evitar que se caiga para abajo
            mosquita.physicsBody!.applyImpulse(CGVector(dx: 0, dy: 500))
        } else {
            // si toca la pantalla cuando el juego ha acabado, lo reiniciamos para volver a jugar
            gameOver = false
            puntuacion = 0
            self.speed = 1
            self.removeAllChildren()
            reiniciar()
        }
        
    }
    
    // Función para tratar las colisiones o contactos de nuestros nodos
    func didBegin(_ contact: SKPhysicsContact) {
        // en contact tenemos bodyA y bodyB que son los cuerpos que hicieron contacto
        let cuerpoA = contact.bodyA
        let cuerpoB = contact.bodyB
        // Miramos si la mosca ha pasado por el hueco
        if (cuerpoA.categoryBitMask == tipoNodo.mosquita.rawValue && cuerpoB.categoryBitMask == tipoNodo.huecoTubos.rawValue) || (cuerpoA.categoryBitMask == tipoNodo.huecoTubos.rawValue && cuerpoB.categoryBitMask == tipoNodo.mosquita.rawValue) {
            puntuacion += 1
            labelPuntuacion.text = String(puntuacion)
        } else {
            // si no pasa por el hueco es porque ha tocado el suelo o una tubería
            // deberemos acabar el juego
            gameOver = true
            // Frenamos todo
            self.speed = 0
            // Paramos el timer
            timer.invalidate()
            labelPuntuacion.text = "Game Over"
        }
        
    }
   
    
    @objc func addHazard() {
        // Random image

        hazards = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: hazards) as! [String]
        let imageName = hazards[0]
        let hazard = SKSpriteNode(imageNamed: imageName)
        hazard.setScale(0.1)
        let deleteHazards = SKAction.removeFromParent()

        hazard.userData = [ "hazardType": imageName ]
        // Random position
        let randomHazardPosition = GKRandomDistribution(lowestValue: Int(self.frame.minY + hazard.size.height), highestValue: Int(self.frame.maxY + hazard.size.height))
        let position = CGFloat(randomHazardPosition.nextInt())
        hazard.zPosition = 1
        //hazard.position = CGPoint(x: self.frame.maxX + hazard.size.width, y: position)
        hazard.position = CGPoint(x:self.frame.maxX  ,y: position)
        // Physical properties
    let mine = SKTexture(imageNamed: "mine")
        hazard.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "mine"), alphaThreshold: 0.5, size: mine.size())
        hazard.physicsBody?.isDynamic = true
        // Collision mask
        hazard.physicsBody?.categoryBitMask = hazardCategory
        hazard.physicsBody?.contactTestBitMask = photonTorperdoCategory | playerCategory
        hazard.physicsBody?.collisionBitMask = 0
        hazard.physicsBody?.affectedByGravity = false
        self.addChild(hazard)
        // Alien basic movement
        let animationDuration:TimeInterval = 6
        let actionMove = SKAction.moveBy(x:-self.frame.maxX, y: 0, duration: animationDuration)
        let actionRemove = SKAction.removeFromParent()
        let actionLeftRight = SKAction.sequence([ actionMove, actionRemove ])
        if imageName != "alien4" {
            // SIMPLE: Top-down movement & Remove after
            hazard.run(actionLeftRight)
        }
        else {
            // COMPLEX: SIMPLE + Left-to-right oscillation & Sprite animation
            // Load from Actions.sks
            let alien4 = SKAction.init(named: "Alien4")!
            // Execute simultaneously
            hazard.run(SKAction.group([alien4, actionLeftRight]))
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
